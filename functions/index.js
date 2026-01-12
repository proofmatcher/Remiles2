const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripeLib = require("stripe");
const express = require("express");

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialize Stripe lazily to avoid errors during deployment
// if config is not set yet
let stripe = null;
/**
 * Get or initialize Stripe instance
 * @return {stripe} Stripe instance
 */
function getStripe() {
  if (!stripe) {
    const stripeConfig = functions.config().stripe;
    const secretKey = stripeConfig && stripeConfig.secret_key;
    if (!secretKey) {
      throw new Error("Stripe secret key not configured. " +
        "Run: firebase functions:config:set stripe.secret_key=\"sk_test_...\"");
    }
    stripe = stripeLib(secretKey);
  }
  return stripe;
}

/**
 * Helper function to send push notification only (no Firestore save)
 * Used for chat messages that should only show as push notifications
 */
async function sendPushNotificationOnly({
  userId,
  title,
  body,
  data = {},
}) {
  try {
    // Get user's FCM token - check users and role-specific collections
    let fcmToken = null;

    // First check users collection
    const userDoc = await admin.firestore()
        .collection("users").doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      fcmToken = userData && userData.fcmToken ?
          userData.fcmToken : null;
    }

    // If not found, check shippers collection
    if (!fcmToken) {
      const shipperDoc = await admin.firestore()
          .collection("shippers").doc(userId).get();
      if (shipperDoc.exists) {
        const shipperData = shipperDoc.data();
        fcmToken = shipperData && shipperData.fcmToken ?
            shipperData.fcmToken : null;
      }
    }

    // If still not found, check carriers collection
    if (!fcmToken) {
      const carrierDoc = await admin.firestore()
          .collection("carriers").doc(userId).get();
      if (carrierDoc.exists) {
        const carrierData = carrierDoc.data();
        fcmToken = carrierData && carrierData.fcmToken ?
            carrierData.fcmToken : null;
      }
    }

    if (fcmToken) {
      // Send push notification via FCM
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...Object.keys(data).reduce((acc, key) => {
            acc[key] = String(data[key]);
            return acc;
          }, {}),
        },
        token: fcmToken,
      };

      try {
        await admin.messaging().send(message);
        console.log(`Push notification sent to user ${userId}`);
      } catch (fcmError) {
        console.error(`Failed to send push notification:`, fcmError);
      }
    }
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

/**
 * Helper function to send notifications
 * Creates notification in Firestore and sends push via FCM
 */
async function sendNotification({
  userId,
  type,
  title,
  body,
  data = {},
  relatedId = null,
}) {
  try {
    // Create notification document in Firestore
    const notificationRef = admin.firestore().collection("notifications").doc();
    await notificationRef.set({
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      relatedId: relatedId,
    });

    // Get user's FCM token - check users and role-specific collections
    let fcmToken = null;

    // First check users collection
    const userDoc = await admin.firestore()
        .collection("users").doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      fcmToken = userData && userData.fcmToken ?
          userData.fcmToken : null;
    }

    // If not found, check shippers collection
    if (!fcmToken) {
      const shipperDoc = await admin.firestore()
          .collection("shippers").doc(userId).get();
      if (shipperDoc.exists) {
        const shipperData = shipperDoc.data();
        fcmToken = shipperData && shipperData.fcmToken ?
            shipperData.fcmToken : null;
      }
    }

    // If still not found, check carriers collection
    if (!fcmToken) {
      const carrierDoc = await admin.firestore()
          .collection("carriers").doc(userId).get();
      if (carrierDoc.exists) {
        const carrierData = carrierDoc.data();
        fcmToken = carrierData && carrierData.fcmToken ?
            carrierData.fcmToken : null;
      }
    }

    if (fcmToken) {
      // Send push notification via FCM
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          notificationId: notificationRef.id,
          ...Object.keys(data).reduce((acc, key) => {
            acc[key] = String(data[key]);
            return acc;
          }, {}),
        },
        token: fcmToken,
      };

      try {
        await admin.messaging().send(message);
        console.log(`Push notification sent to user ${userId}`);
      } catch (fcmError) {
        console.error(`Failed to send push notification:`, fcmError);
        // Continue even if FCM fails - notification is still saved in Firestore
      }
    }

    console.log(`Notification created for user ${userId}: ${title}`);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

/**
 * Create a Stripe Payment Intent
 *
 * This function securely creates a payment intent on the server side
 * using the Stripe secret key. It requires user authentication.
 *
 * @param {Object} data - Payment data
 * @param {number} data.amount - Amount in cents
 * @param {string} data.currency - Currency code (default: 'usd')
 * @param {Object} data.metadata - Additional metadata for the payment
 * @param {Object} context - Firebase Functions context
 * @returns {Object} Payment intent with client secret
 */
// Using Canadian region for data residency compliance.
// Using regular HTTP function instead of callable to allow manual auth token.
// This works around Flutter SDK bug with custom regions.
exports.createPaymentIntent = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      // Handle preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token from header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        console.error("Missing or invalid Authorization header");
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated to create a payment intent",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify the token and get user
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        console.log("User authenticated:", decodedToken.uid);
      } catch (error) {
        console.error("Token verification failed:", error);
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        // Parse request body
        const requestData = req.body.data || req.body;
        const {amount, currency = "usd", metadata = {}} = requestData;

        // Validate amount
        if (!amount || amount <= 0) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Amount must be greater than 0",
            },
          });
          return;
        }

        // Validate currency
        if (typeof currency !== "string" || currency.length !== 3) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Currency must be a valid 3-letter code",
            },
          });
          return;
        }

        // Add user ID to metadata for tracking
        const paymentMetadata = {
          ...metadata,
          userId: decodedToken.uid,
          userEmail: decodedToken.email || "unknown",
          createdAt: new Date().toISOString(),
        };

        // Create payment intent with Stripe
        const stripe = getStripe();
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amount, // Amount in cents
          currency: currency.toLowerCase(),
          metadata: paymentMetadata,
          // Optional: Add automatic payment methods
          automatic_payment_methods: {
            enabled: true,
          },
        });

        // Log payment intent creation in Firestore (optional)
        try {
          await admin.firestore().collection("payment_intents").add({
            userId: decodedToken.uid,
            paymentIntentId: paymentIntent.id,
            amount: amount,
            currency: currency,
            status: paymentIntent.status,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: paymentMetadata,
          });
        } catch (logError) {
          // Don't fail the payment if logging fails
          console.error("Failed to log payment intent:", logError);
        }

        // Return response in callable format for compatibility
        res.status(200).json({
          result: {
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
          },
        });
      } catch (error) {
        console.error("Error creating payment intent:", error);

        // Log error details for debugging
        console.error("Error type:", error.type || typeof error);
        console.error("Error message:", error.message);
        console.error("Error stack:", error.stack);

        // Handle Stripe errors
        let statusCode = 500;
        let errorStatus = "INTERNAL";
        let errorMessage = "Failed to create payment intent";

        if (error.type === "StripeCardError") {
          statusCode = 400;
          errorStatus = "FAILED_PRECONDITION";
          errorMessage = error.message || "Card payment failed";
        } else if (error.type === "StripeInvalidRequestError") {
          statusCode = 400;
          errorStatus = "INVALID_ARGUMENT";
          errorMessage = error.message || "Invalid payment request";
        } else {
          errorMessage = error.message || "Unknown error";
        }

        res.status(statusCode).json({
          error: {
            status: errorStatus,
            message: errorMessage,
          },
        });
      }
    });

/**
 * Webhook handler for Stripe events
 *
 * This function handles Stripe webhook events to update payment status
 * in Firestore when payments are completed or fail.
 *
 * To set up the webhook:
 * 1. Go to Stripe Dashboard > Developers > Webhooks
 * 2. Add endpoint:
 *    YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook
 * 3. Select events: payment_intent.succeeded, payment_intent.payment_failed
 * 4. Copy webhook signing secret and set:
 *    firebase functions:config:set stripe.webhook_secret="whsec_..."
 */
// Create Express app for webhook with raw body parsing
const webhookApp = express();
webhookApp.use(
    express.raw({type: "application/json"}),
);

webhookApp.post("/", async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = functions.config().stripe.webhook_secret;

  if (!webhookSecret) {
    console.error("Webhook secret not configured");
    return res.status(500).send("Webhook secret not configured");
  }

  let event;

  try {
    // Verify webhook signature using raw body
    const stripe = getStripe();
    event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        webhookSecret,
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case "payment_intent.succeeded": {
      const paymentIntent = event.data.object;
      console.log("PaymentIntent succeeded:", paymentIntent.id);

      // Update Firestore with payment success
      try {
        const userId = paymentIntent.metadata &&
            paymentIntent.metadata.userId;
        if (userId) {
          await admin.firestore()
              .collection("payment_intents")
              .where("paymentIntentId", "==", paymentIntent.id)
              .get()
              .then(async (snapshot) => {
                if (!snapshot.empty) {
                  const docRef = snapshot.docs[0].ref;
                  await docRef.update({
                    status: "succeeded",
                    succeededAt: admin.firestore.FieldValue
                        .serverTimestamp(),
                  });

                  // Send notification
                  const paymentAmount = (paymentIntent.amount / 100)
                      .toFixed(2);
                  await sendNotification({
                    userId: userId,
                    type: "paymentReceived",
                    title: "Payment Received",
                    body: `Your payment of $${paymentAmount} ` +
                        "has been received successfully.",
                    data: {
                      paymentIntentId: paymentIntent.id,
                      amount: paymentIntent.amount,
                    },
                    relatedId: paymentIntent.id,
                  });
                }
              });
        }
      } catch (error) {
        console.error("Error updating payment status:", error);
      }
      break;
    }

    case "payment_intent.payment_failed": {
      const failedPayment = event.data.object;
      console.log("PaymentIntent failed:", failedPayment.id);

      // Update Firestore with payment failure
      try {
        const userId = failedPayment.metadata &&
            failedPayment.metadata.userId;
        if (userId) {
          const lastError = failedPayment.last_payment_error;
          const errorMessage = (lastError && lastError.message) ||
              "Unknown error";
          await admin.firestore()
              .collection("payment_intents")
              .where("paymentIntentId", "==", failedPayment.id)
              .get()
              .then(async (snapshot) => {
                if (!snapshot.empty) {
                  await snapshot.docs[0].ref.update({
                    status: "failed",
                    failedAt: admin.firestore.FieldValue.serverTimestamp(),
                    failureReason: errorMessage,
                  });

                  // Send notification
                  await sendNotification({
                    userId: userId,
                    type: "paymentFailed",
                    title: "Payment Failed",
                    body: `Your payment failed: ${errorMessage}`,
                    data: {
                      paymentIntentId: failedPayment.id,
                      error: errorMessage,
                    },
                    relatedId: failedPayment.id,
                  });
                }
              });
        }
      } catch (error) {
        console.error("Error updating payment failure:", error);
      }
      break;
    }

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  // Return a response to acknowledge receipt of the event
  res.json({received: true});
});

// Export as Firebase Function
exports.handleStripeWebhook = functions
    .region("northamerica-northeast1")
    .https.onRequest(webhookApp);

/**
 * Firestore trigger: Send notification when load status changes
 */
exports.onLoadStatusChange = functions
    .region("northamerica-northeast1")
    .firestore.document("loads/{loadId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const loadId = context.params.loadId;

      // Only trigger if status actually changed
      if (before.status === after.status) {
        return null;
      }

      const newStatus = after.status;
      const oldStatus = before.status;

      try {
        // Notify shipper about status change
        if (after.shipperId) {
          let title = "Order Status Updated";
          let body = `Your order status has been updated to ${newStatus}.`;

          if (newStatus === "booked") {
            title = "Order Booked";
            body = "A carrier has accepted your order!";
          } else if (newStatus === "in-transit") {
            title = "Order In Transit";
            body = "Your order is now in transit.";
          } else if (newStatus === "completed") {
            title = "Order Completed";
            body = "Your order has been completed successfully!";
          }

          await sendNotification({
            userId: after.shipperId,
            type: "orderStatus",
            title: title,
            body: body,
            data: {
              loadId: loadId,
              oldStatus: oldStatus,
              newStatus: newStatus,
            },
            relatedId: loadId,
          });
        }

        // Notify carrier about status change
        if (after.bookedByCarrierId) {
          let title = "Order Status Updated";
          let body = `The order status has been updated to ${newStatus}.`;

          if (newStatus === "in-transit") {
            title = "Order In Transit";
            body = "You've marked the order as in transit.";
          } else if (newStatus === "completed") {
            title = "Order Completed";
            body = "You've completed the order successfully!";
          }

          await sendNotification({
            userId: after.bookedByCarrierId,
            type: "orderStatus",
            title: title,
            body: body,
            data: {
              loadId: loadId,
              oldStatus: oldStatus,
              newStatus: newStatus,
            },
            relatedId: loadId,
          });
        }
      } catch (error) {
        console.error("Error sending load status notification:", error);
      }

      return null;
    });

/**
 * Firestore trigger: Send notification when offer is created
 */
exports.onOfferCreated = functions
    .region("northamerica-northeast1")
    .firestore
    .document("offers/{offerId}")
    .onCreate(async (snap, context) => {
      const offerData = snap.data();

      try {
        // Notify shipper when carrier sends an offer
        if (offerData.shipperId && offerData.offerAmount) {
          await sendNotification({
            userId: offerData.shipperId,
            type: "offerReceived",
            title: "New Offer Received",
            body: `You received an offer of $${offerData.offerAmount
                .toFixed(2)}`,
            data: {
              offerId: context.params.offerId,
              loadId: offerData.loadId,
              offerAmount: offerData.offerAmount,
              carrierId: offerData.carrierId,
              carrierName: offerData.carrierName || "Carrier",
            },
            relatedId: context.params.offerId,
          });
        }
      } catch (error) {
        console.error("Error sending offer created notification:", error);
      }

      return null;
    });

/**
 * Firestore trigger: Send notification when offer status changes
 */
exports.onOfferStatusChange = functions
    .region("northamerica-northeast1")
    .firestore.document("offers/{offerId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      try {
        // Check if offer was just accepted
        if (before.status !== "accepted" && after.status === "accepted") {
          // Notify carrier
          if (after.carrierId) {
            await sendNotification({
              userId: after.carrierId,
              type: "offerAccepted",
              title: "Offer Accepted!",
              body: `Your offer of $${(after.offerAmount != null &&
                  typeof after.offerAmount === "number") ?
                  after.offerAmount.toFixed(2) : "N/A"} has been accepted!`,
              data: {
                offerId: context.params.offerId,
                loadId: after.loadId,
                offerAmount: after.offerAmount,
              },
              relatedId: context.params.offerId,
            });
          }

          // Notify shipper (use shipperId from offer document)
          if (after.shipperId) {
            await sendNotification({
              userId: after.shipperId,
              type: "offerAccepted",
              title: "Offer Accepted",
              body: `You've accepted an offer of $${(after.offerAmount !=
                  null && typeof after.offerAmount === "number") ?
                  after.offerAmount.toFixed(2) : "N/A"}.`,
              data: {
                offerId: context.params.offerId,
                loadId: after.loadId,
                offerAmount: after.offerAmount,
              },
              relatedId: context.params.offerId,
            });
          }
        }

        // Check if offer was just rejected
        if (before.status !== "rejected" && after.status === "rejected") {
          // Notify carrier when shipper rejects
          if (after.carrierId) {
            const offerAmount = (after.offerAmount != null &&
                typeof after.offerAmount === "number") ?
                after.offerAmount.toFixed(2) : "N/A";
            await sendNotification({
              userId: after.carrierId,
              type: "offerRejected",
              title: "Offer Rejected",
              body: `Your offer of $${offerAmount} was rejected.`,
              data: {
                offerId: context.params.offerId,
                loadId: after.loadId,
                offerAmount: after.offerAmount,
              },
              relatedId: context.params.offerId,
            });
          }
        }

        // Check if counter-offer was made
        const isCounterOffered = before.status !== "counterOffered" &&
            after.status === "counterOffered";
        if (isCounterOffered) {
          // Notify carrier when shipper makes counter-offer
          if (after.carrierId && after.counterOfferAmount) {
            await sendNotification({
              userId: after.carrierId,
              type: "counterOfferReceived",
              title: "Counter-Offer Received",
              body: `Shipper counter-offered $${after.counterOfferAmount
                  .toFixed(2)}`,
              data: {
                offerId: context.params.offerId,
                loadId: after.loadId,
                counterOfferAmount: after.counterOfferAmount,
                originalOfferAmount: after.offerAmount,
              },
              relatedId: context.params.offerId,
            });
          }
        }
      } catch (error) {
        console.error("Error sending offer status change notification:", error);
      }

      return null;
    });

/**
 * Firestore trigger: Send notification when a message is sent
 */
exports.onMessageCreated = functions
    .region("northamerica-northeast1")
    .firestore.document("messages/{messageId}")
    .onCreate(async (snap, context) => {
      const messageData = snap.data();
      const conversationId = messageData.conversationId;
      const senderId = messageData.senderId;
      const receiverId = messageData.receiverId;
      const content = messageData.content || "";
      const messageType = messageData.type || "text";

      try {
        // Check if this is a support conversation
        const convDoc = await admin.firestore()
            .collection("conversations")
            .doc(conversationId)
            .get();

        if (!convDoc.exists) {
          return null;
        }

        const convData = convDoc.data();
        const isSupportConversation = convData && convData.isSupport === true;

        if (isSupportConversation) {
          // For support conversations, save to notifications page
          await sendNotification({
            userId: receiverId,
            type: "message",
            title: senderId === "support_system" ?
                "Support Team Replied" :
                "New Support Message",
            body: content.length > 50 ?
                content.substring(0, 50) + "..." : content,
            data: {
              conversationId: conversationId,
              senderId: senderId,
              messageId: context.params.messageId,
            },
            relatedId: conversationId,
          });
        } else {
          // For regular chat messages, send push only (no Firestore save)
          // Skip if it's an offer message (handled by offer triggers)
          if (messageType !== "offer") {
            // Get sender name for notification
            let senderName = "Someone";
            try {
              const senderDoc = await admin.firestore()
                  .collection("users").doc(senderId).get();
              if (senderDoc.exists) {
                const senderData = senderDoc.data();
                senderName = (senderData && senderData.displayName) ||
                    (senderData && senderData.name) || "Someone";
              } else {
                // Try shippers collection
                const shipperDoc = await admin.firestore()
                    .collection("shippers").doc(senderId).get();
                if (shipperDoc.exists) {
                  const shipperData = shipperDoc.data();
                  senderName = (shipperData && shipperData.companyName) ||
                      (shipperData && shipperData.displayName) || "Someone";
                } else {
                  // Try carriers collection
                  const carrierDoc = await admin.firestore()
                      .collection("carriers").doc(senderId).get();
                  if (carrierDoc.exists) {
                    const carrierData = carrierDoc.data();
                    senderName = (carrierData && carrierData.companyName) ||
                        (carrierData && carrierData.displayName) || "Someone";
                  }
                }
              }
            } catch (e) {
              console.error("Error getting sender name:", e);
            }

            await sendPushNotificationOnly({
              userId: receiverId,
              title: senderName,
              body: content.length > 100 ?
                  content.substring(0, 100) + "..." : content,
              data: {
                type: "message",
                conversationId: conversationId,
                senderId: senderId,
                messageId: context.params.messageId,
              },
            });
          }
        }
      } catch (error) {
        console.error("Error sending message notification:", error);
      }

      return null;
    });

/**
 * Firestore trigger: Send notification when escrow payment
 * status changes to deposited
 */
exports.onEscrowPaymentStatusChange = functions
    .region("northamerica-northeast1")
    .firestore.document("escrow_payments/{escrowPaymentId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      try {
        // Check if payment status changed from pending to deposited
        if (before.status === "pending" && after.status === "deposited") {
          const carrierId = after.carrierId;
          const loadId = after.loadId;
          // Calculate amount - amountInDollars preferred,
          // otherwise convert from cents
          const amount = after.amountInDollars != null ?
              after.amountInDollars :
              (after.amount != null ? after.amount / 100 : 0);

          if (carrierId && loadId) {
            // Send notification to carrier
            const bodyMessage = `Payment of $${amount.toFixed(2)} ` +
                "has been deposited to escrow. " +
                "You can now proceed to the pickup location.";
            await sendNotification({
              userId: carrierId,
              type: "paymentReceived",
              title: "Payment Deposited - Ready for Pickup!",
              body: bodyMessage,
              data: {
                loadId: loadId,
                amount: amount,
                escrowPaymentId: context.params.escrowPaymentId,
                paymentIntentId: after.paymentIntentId,
              },
              relatedId: loadId,
            });

            console.log(
                `Escrow payment notification sent to carrier ` +
                `${carrierId} for load ${loadId}`,
            );
          }
        }
      } catch (error) {
        console.error("Error sending escrow payment notification:", error);
      }

      return null;
    });

/**
 * Create a Setup Intent for saving payment methods
 * This allows users to save payment methods without making a payment
 */
exports.createSetupIntent = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      // Handle preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token from header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify the token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();

        // Get or create Stripe customer - support both shippers and carriers
        let customerId;
        let userCollection = "shippers"; // default

        // Check if user is a shipper
        let userDoc = await admin.firestore()
            .collection("shippers")
            .doc(decodedToken.uid)
            .get();

        // If not a shipper, check if user is a carrier
        if (!userDoc.exists) {
          userDoc = await admin.firestore()
              .collection("carriers")
              .doc(decodedToken.uid)
              .get();
          if (userDoc.exists) {
            userCollection = "carriers";
          }
        }

        if (userDoc.exists && userDoc.data().stripeCustomerId) {
          customerId = userDoc.data().stripeCustomerId;
          // Verify the customer belongs to this user
          try {
            const existingCustomer =
                await stripe.customers.retrieve(customerId);
            if (existingCustomer.metadata && existingCustomer.metadata.userId) {
              if (existingCustomer.metadata.userId !== decodedToken.uid) {
                console.error(
                    `Security issue: Customer ${customerId} belongs to user ` +
                    `${existingCustomer.metadata.userId} but request is from ` +
                    `${decodedToken.uid}`);
                // Don't use this customer - create a new one
                customerId = null;
              }
            }
          } catch (error) {
            console.error("Error verifying existing customer:", error);
            // If we can't verify, don't use it - create a new one
            customerId = null;
          }
        }

        if (!customerId) {
          // Create new Stripe customer
          const customer = await stripe.customers.create({
            email: decodedToken.email,
            metadata: {
              userId: decodedToken.uid,
            },
          });
          customerId = customer.id;

          // Save customer ID to Firestore in the correct collection
          if (userDoc.exists) {
            await admin.firestore()
                .collection(userCollection)
                .doc(decodedToken.uid)
                .update({
                  stripeCustomerId: customerId,
                });
          } else {
            // If user doesn't exist in either collection,
            // create in shippers (fallback)
            await admin.firestore()
                .collection("shippers")
                .doc(decodedToken.uid)
                .set({
                  stripeCustomerId: customerId,
                }, {merge: true});
          }
        }

        // Create setup intent
        const setupIntent = await stripe.setupIntents.create({
          customer: customerId,
          payment_method_types: ["card"],
        });

        res.status(200).json({
          result: {
            clientSecret: setupIntent.client_secret,
            setupIntentId: setupIntent.id,
          },
        });
      } catch (error) {
        console.error("Error creating setup intent:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to create setup intent",
          },
        });
      }
    });

/**
 * List payment methods for a user
 */
exports.listPaymentMethods = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "GET") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();
        const userId = decodedToken.uid;

        // Get Stripe customer ID - support both shippers and carriers
        let userDoc = await admin.firestore()
            .collection("shippers")
            .doc(userId)
            .get();

        // If not a shipper, check if user is a carrier
        if (!userDoc.exists) {
          userDoc = await admin.firestore()
              .collection("carriers")
              .doc(userId)
              .get();
        }

        if (!userDoc.exists) {
          console.log(`User ${userId} not found in shippers or carriers`);
          res.status(200).json({
            result: {
              paymentMethods: [],
            },
          });
          return;
        }

        const userData = userDoc.data();
        const customerId = userData.stripeCustomerId;

        if (!customerId || typeof customerId !== "string") {
          console.log(`User ${userId} does not have a valid stripeCustomerId`);
          res.status(200).json({
            result: {
              paymentMethods: [],
            },
          });
          return;
        }

        // Verify the customer belongs to this user by checking metadata
        const customer = await stripe.customers.retrieve(customerId);
        if (customer.metadata && customer.metadata.userId) {
          if (customer.metadata.userId !== userId) {
            console.error(
                `Security issue: Customer ${customerId} belongs to user ` +
                `${customer.metadata.userId} but request is from ${userId}`);
            res.status(403).json({
              error: {
                status: "PERMISSION_DENIED",
                message: "Access denied to payment methods",
              },
            });
            return;
          }
        }

        // Get default payment method
        const defaultPaymentMethodId = customer.invoice_settings &&
            customer.invoice_settings.default_payment_method;

        // List payment methods - CRITICAL: filter by customer ID
        const paymentMethods = await stripe.paymentMethods.list({
          customer: customerId,
          type: "card",
        });

        console.log(
            `Found ${paymentMethods.data.length} payment methods for user ` +
            `${userId} (customer: ${customerId})`);

        // Format payment methods
        const formattedMethods = paymentMethods.data.map((pm) => ({
          id: pm.id,
          type: pm.type,
          card: {
            brand: pm.card.brand,
            last4: pm.card.last4,
            expMonth: pm.card.exp_month,
            expYear: pm.card.exp_year,
          },
          isDefault: pm.id === defaultPaymentMethodId,
        }));

        res.status(200).json({
          result: {
            paymentMethods: formattedMethods,
          },
        });
      } catch (error) {
        console.error("Error listing payment methods:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to list payment methods",
          },
        });
      }
    });

/**
 * Set default payment method
 */
exports.setDefaultPaymentMethod = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const requestData = req.body.data || req.body;
        const {paymentMethodId} = requestData;

        if (!paymentMethodId) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Payment method ID is required",
            },
          });
          return;
        }

        const stripe = getStripe();

        // Get Stripe customer ID - support both shippers and carriers
        let userDoc = await admin.firestore()
            .collection("shippers")
            .doc(decodedToken.uid)
            .get();

        let userCollection = "shippers"; // default

        // If not a shipper, check if user is a carrier
        if (!userDoc.exists) {
          userDoc = await admin.firestore()
              .collection("carriers")
              .doc(decodedToken.uid)
              .get();
          if (userDoc.exists) {
            userCollection = "carriers";
          }
        }

        if (!userDoc.exists || !userDoc.data().stripeCustomerId) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Stripe customer not found",
            },
          });
          return;
        }

        const customerId = userDoc.data().stripeCustomerId;
        const userId = decodedToken.uid;

        // Verify the customer belongs to this user
        const customer = await stripe.customers.retrieve(customerId);
        if (customer.metadata && customer.metadata.userId) {
          if (customer.metadata.userId !== userId) {
            console.error(
                `Security issue: Customer ${customerId} belongs to user ` +
                `${customer.metadata.userId} but request is from ${userId}`);
            res.status(403).json({
              error: {
                status: "PERMISSION_DENIED",
                message: "Access denied",
              },
            });
            return;
          }
        }

        // Verify the payment method belongs to this customer
        try {
          const paymentMethod = await stripe.paymentMethods.retrieve(
              paymentMethodId);
          if (paymentMethod.customer !== customerId) {
            console.error(
                `Security issue: Payment method ${paymentMethodId} ` +
                `belongs to customer ${paymentMethod.customer} but user ` +
                `${userId} tried to set it as default for ` +
                `customer ${customerId}`);
            res.status(403).json({
              error: {
                status: "PERMISSION_DENIED",
                message: "Payment method does not belong to your account",
              },
            });
            return;
          }
        } catch (pmError) {
          console.error("Error retrieving payment method:", pmError);
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Payment method not found",
            },
          });
          return;
        }

        // Set default payment method in Stripe
        await stripe.customers.update(customerId, {
          invoice_settings: {
            default_payment_method: paymentMethodId,
          },
        });

        // Store default payment method ID in Firebase
        try {
          await admin.firestore()
              .collection(userCollection)
              .doc(decodedToken.uid)
              .update({
                defaultPaymentMethodId: paymentMethodId,
                lastPaymentMethodUpdate:
                    admin.firestore.FieldValue.serverTimestamp(),
              });
        } catch (firestoreError) {
          console.error(
              "Error storing default payment method in Firebase:",
              firestoreError);
          // Don't fail the request if Firestore update fails
        }

        res.status(200).json({
          result: {
            success: true,
          },
        });
      } catch (error) {
        console.error("Error setting default payment method:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to set default payment method",
          },
        });
      }
    });

/**
 * Delete payment method
 */
exports.deletePaymentMethod = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const requestData = req.body.data || req.body;
        const {paymentMethodId} = requestData;

        if (!paymentMethodId) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Payment method ID is required",
            },
          });
          return;
        }

        const stripe = getStripe();

        // Get Stripe customer ID - support both shippers and carriers
        let userDoc = await admin.firestore()
            .collection("shippers")
            .doc(decodedToken.uid)
            .get();

        // If not a shipper, check if user is a carrier
        if (!userDoc.exists) {
          userDoc = await admin.firestore()
              .collection("carriers")
              .doc(decodedToken.uid)
              .get();
        }

        if (!userDoc.exists || !userDoc.data().stripeCustomerId) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Stripe customer not found",
            },
          });
          return;
        }

        const customerId = userDoc.data().stripeCustomerId;
        const userId = decodedToken.uid;

        // Verify the customer belongs to this user
        const customer = await stripe.customers.retrieve(customerId);
        if (customer.metadata && customer.metadata.userId) {
          if (customer.metadata.userId !== userId) {
            console.error(
                `Security issue: Customer ${customerId} belongs to user ` +
                `${customer.metadata.userId} but request is from ${userId}`);
            res.status(403).json({
              error: {
                status: "PERMISSION_DENIED",
                message: "Access denied",
              },
            });
            return;
          }
        }

        // Verify the payment method belongs to this customer
        try {
          const paymentMethod = await stripe.paymentMethods.retrieve(
              paymentMethodId);
          if (paymentMethod.customer !== customerId) {
            console.error(
                `Security issue: Payment method ${paymentMethodId} ` +
                `belongs to customer ${paymentMethod.customer} but user ` +
                `${userId} tried to delete it from ` +
                `customer ${customerId}`);
            res.status(403).json({
              error: {
                status: "PERMISSION_DENIED",
                message: "Payment method does not belong to your account",
              },
            });
            return;
          }
        } catch (pmError) {
          console.error("Error retrieving payment method:", pmError);
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Payment method not found",
            },
          });
          return;
        }

        // Check if this is the default payment method
        const defaultPaymentMethodId = customer.invoice_settings &&
            customer.invoice_settings.default_payment_method;

        // Delete payment method
        await stripe.paymentMethods.detach(paymentMethodId);

        // If it was the default, clear the default
        if (paymentMethodId === defaultPaymentMethodId) {
          await stripe.customers.update(customerId, {
            invoice_settings: {
              default_payment_method: null,
            },
          });
        }

        res.status(200).json({
          result: {
            success: true,
          },
        });
      } catch (error) {
        console.error("Error deleting payment method:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to delete payment method",
          },
        });
      }
    });

/**
 * Create Stripe Connect account for carrier
 *
 * This function creates a Stripe Connect Express account for a carrier
 * so they can receive payment transfers.
 *
 * NOTE: Only carriers need Connect accounts to receive money.
 * Shippers only need Stripe Customer accounts (for storing payment methods
 * to send money), which are handled by createSetupIntent.
 */
exports.createConnectAccount = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();
        const userId = decodedToken.uid;

        // Verify user is a carrier
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .get();

        if (!carrierDoc.exists) {
          res.status(403).json({
            error: {
              status: "PERMISSION_DENIED",
              message: "Only carriers can create Connect accounts",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();

        // Check if account already exists
        if (carrierData.stripeAccountId) {
          res.status(200).json({
            result: {
              accountId: carrierData.stripeAccountId,
              alreadyExists: true,
            },
          });
          return;
        }

        // Create Stripe Connect Express account
        const account = await stripe.accounts.create({
          type: "express",
          country: "CA", // Canada
          email: decodedToken.email,
          capabilities: {
            card_payments: {requested: true},
            transfers: {requested: true},
          },
          metadata: {
            userId: userId,
            userType: "carrier",
          },
        });

        // Save account ID to Firebase
        await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .update({
              stripeAccountId: account.id,
            });

        res.status(200).json({
          result: {
            accountId: account.id,
            accountType: account.type,
            chargesEnabled: account.charges_enabled,
            payoutsEnabled: account.payouts_enabled,
            alreadyExists: false,
          },
        });
      } catch (error) {
        console.error("Error creating Connect account:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to create Connect account",
          },
        });
      }
    });

/**
 * Create Account Link for Stripe Connect onboarding
 *
 * This function generates an onboarding URL for carriers to complete
 * their Stripe Connect account setup.
 *
 * NOTE: Only carriers need this. Shippers don't need Connect accounts
 * since they only send money (not receive it).
 */
exports.createAccountLink = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();
        const userId = decodedToken.uid;

        // Get carrier's Connect account ID
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .get();

        if (!carrierDoc.exists) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Carrier not found",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();
        const accountId = carrierData.stripeAccountId;

        if (!accountId) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Carrier does not have a Connect account. " +
                  "Create one first using createConnectAccount.",
            },
          });
          return;
        }

        // Get request data for return URL
        const requestData = req.body.data || req.body;
        // Use a simple return URL - for mobile apps, this is just a
        // redirect target. The actual return happens when user manually
        // returns to app
        const returnUrl = requestData.returnUrl ||
            "https://stripe.com";

        console.log(`Creating Account Link for account ${accountId}`);
        console.log(`Return URL: ${returnUrl}`);

        // Create Account Link for onboarding
        const accountLink = await stripe.accountLinks.create({
          account: accountId,
          refresh_url: returnUrl,
          return_url: returnUrl,
          type: "account_onboarding",
        });

        console.log(`Account Link created: ${accountLink.url}`);
        console.log(`Expires at: ${accountLink.expires_at}`);

        res.status(200).json({
          result: {
            url: accountLink.url,
            expiresAt: accountLink.expires_at,
          },
        });
      } catch (error) {
        console.error("Error creating Account Link:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to create Account Link",
          },
        });
      }
    });

/**
 * Get Stripe Connect account status
 *
 * This function retrieves the status of a carrier's Connect account,
 * including whether it's activated, restricted, or needs onboarding.
 *
 * NOTE: Only carriers need Connect accounts to receive money.
 */
exports.getConnectAccountStatus = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "GET") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();
        const userId = decodedToken.uid;

        // Get carrier's Connect account ID
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .get();

        if (!carrierDoc.exists) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Carrier not found",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();
        const accountId = carrierData.stripeAccountId;

        if (!accountId) {
          res.status(200).json({
            result: {
              hasAccount: false,
              accountId: null,
              chargesEnabled: false,
              payoutsEnabled: false,
              detailsSubmitted: false,
              needsOnboarding: true,
            },
          });
          return;
        }

        // Retrieve account from Stripe
        const account = await stripe.accounts.retrieve(accountId);

        // Check if account needs onboarding
        const needsOnboarding = !account.details_submitted ||
            !account.charges_enabled || !account.payouts_enabled;

        res.status(200).json({
          result: {
            hasAccount: true,
            accountId: account.id,
            chargesEnabled: account.charges_enabled || false,
            payoutsEnabled: account.payouts_enabled || false,
            detailsSubmitted: account.details_submitted || false,
            needsOnboarding: needsOnboarding,
            restrictions: (account.requirements &&
                account.requirements.currently_due) || [],
            disabledReason: (account.requirements &&
                account.requirements.disabled_reason) || null,
          },
        });
      } catch (error) {
        console.error("Error getting Connect account status:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to get Connect account status",
          },
        });
      }
    });

/**
 * Delete Stripe Connect account for carrier
 *
 * This function deletes a Stripe Connect Express account for a carrier.
 * It should be called when a carrier deletes their account.
 *
 * NOTE: This permanently deletes the Stripe account. Any pending payments
 * or transfers should be handled before calling this function.
 */
exports.deleteConnectAccount = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const stripe = getStripe();
        const userId = decodedToken.uid;

        // Verify user is a carrier
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .get();

        if (!carrierDoc.exists) {
          res.status(403).json({
            error: {
              status: "PERMISSION_DENIED",
              message: "Only carriers can delete Connect accounts",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();
        const accountId = carrierData.stripeAccountId;

        if (!accountId) {
          res.status(200).json({
            result: {
              deleted: false,
              message: "No Stripe Connect account found to delete",
            },
          });
          return;
        }

        // Delete the Stripe Connect account
        const deletedAccount = await stripe.accounts.del(accountId);

        // Remove stripeAccountId from Firestore
        await admin.firestore()
            .collection("carriers")
            .doc(userId)
            .update({
              stripeAccountId: admin.firestore.FieldValue.delete(),
            });

        console.log(`Stripe Connect account deleted: ${accountId}`);

        res.status(200).json({
          result: {
            deleted: deletedAccount.deleted || false,
            accountId: accountId,
            message: "Stripe Connect account deleted successfully",
          },
        });
      } catch (error) {
        console.error("Error deleting Connect account:", error);

        // Handle Stripe-specific errors
        if (error.type === "StripeInvalidRequestError") {
          // Account might already be deleted or not exist
          if (error.code === "resource_missing") {
            // Remove stripeAccountId from Firestore even if account
            // doesn't exist
            try {
              await admin.firestore()
                  .collection("carriers")
                  .doc(decodedToken.uid)
                  .update({
                    stripeAccountId: admin.firestore.FieldValue.delete(),
                  });
            } catch (firestoreError) {
              console.error("Error cleaning up Firestore:", firestoreError);
            }

            res.status(200).json({
              result: {
                deleted: false,
                message: "Stripe account not found (may already be deleted)",
              },
            });
            return;
          }
        }

        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to delete Connect account",
          },
        });
      }
    });

/**
 * Delete user account and all associated data
 * This function:
 * 1. Deletes all Firestore documents (user doc, loads, listings,
 *    conversations, messages, etc.)
 * 2. Deletes all storage files
 * 3. Handles Stripe account deletion (for carriers)
 * 4. Deletes Firebase Auth user
 */
exports.deleteUserAccount = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify token
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      const userId = decodedToken.uid;
      const {userRole} = req.body.data || req.body;

      if (!userRole || !["shipper", "carrier"].includes(userRole)) {
        res.status(400).json({
          error: {
            status: "INVALID_ARGUMENT",
            message: "userRole must be 'shipper' or 'carrier'",
          },
        });
        return;
      }

      try {
        console.log(
            `Starting account deletion for user: ${userId}, role: ${userRole}`);

        // Step 1: Get Stripe account ID for carriers
        let stripeAccountId = null;
        if (userRole === "carrier") {
          try {
            const carrierDoc = await admin.firestore()
                .collection("carriers")
                .doc(userId)
                .get();
            if (carrierDoc.exists) {
              const carrierData = carrierDoc.data();
              stripeAccountId =
                  (carrierData && carrierData.stripeAccountId) || null;
            }
          } catch (error) {
            console.error("Error getting carrier Stripe account:", error);
            // Continue with deletion even if we can't get Stripe account ID
          }
        }

        // Step 2: Delete all Firestore data
        const db = admin.firestore();
        const batch = db.batch();

        // Delete user document from shippers or carriers collection
        if (userRole === "shipper") {
          // Delete shipper document
          const shipperRef = db.collection("shippers").doc(userId);
          batch.delete(shipperRef);

          // Delete all loads for this shipper
          const loadsSnapshot = await db
              .collection("shippers")
              .doc(userId)
              .collection("loads")
              .get();
          loadsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          // Delete all listings for this shipper
          const listingsSnapshot = await db
              .collection("listings")
              .where("shipperUid", "==", userId)
              .get();
          listingsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
        } else if (userRole === "carrier") {
          // Delete carrier document
          const carrierRef = db.collection("carriers").doc(userId);
          batch.delete(carrierRef);

          // Delete all bookings for this carrier
          const bookingsSnapshot = await db
              .collection("bookings")
              .where("carrierId", "==", userId)
              .get();
          bookingsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          // Delete all offers for this carrier
          const offersSnapshot = await db
              .collection("offers")
              .where("carrierId", "==", userId)
              .get();
          offersSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
        }

        // Delete conversations where user is a participant
        const conversationsSnapshot = await db
            .collection("conversations")
            .where("participants", "array-contains", userId)
            .get();
        conversationsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        // Delete messages sent by this user
        const messagesSnapshot = await db
            .collection("messages")
            .where("senderId", "==", userId)
            .get();
        messagesSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        // Delete reports filed by this user
        const reportsSnapshot = await db
            .collection("reports")
            .where("reporterId", "==", userId)
            .get();
        reportsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        // Delete from users collection if exists
        const userRef = db.collection("users").doc(userId);
        const userDoc = await userRef.get();
        if (userDoc.exists) {
          batch.delete(userRef);
        }

        // Commit all Firestore deletions
        await batch.commit();
        console.log("Firestore data deleted successfully");

        // Step 3: Delete all storage files
        const bucket = admin.storage().bucket();
        const prefix = userRole === "shipper" ?
            `shippers/${userId}` :
            `carriers/${userId}`;

        try {
          const [files] = await bucket.getFiles({prefix: prefix});
          const deletePromises = files.map((file) =>
            file.delete().catch((err) => {
              console.error(`Error deleting file ${file.name}:`, err);
              // Continue even if individual file deletion fails
            }));
          await Promise.all(deletePromises);
          console.log("Storage files deleted successfully");
        } catch (error) {
          console.error("Error deleting storage files:", error);
          // Continue with deletion even if storage deletion fails
        }

        // Step 4: Handle Stripe account deletion (for carriers)
        if (stripeAccountId && userRole === "carrier") {
          try {
            const stripe = getStripe();
            await stripe.accounts.del(stripeAccountId);
            console.log(`Stripe Connect account deleted: ${stripeAccountId}`);
          } catch (error) {
            console.error("Error deleting Stripe Connect account:", error);
            // Continue with account deletion even if Stripe deletion fails
            // The account data is already deleted from Firestore
          }
        }

        // Step 5: Delete Firebase Auth user (must be done last)
        try {
          await admin.auth().deleteUser(userId);
          console.log("Firebase Auth user deleted successfully");
        } catch (error) {
          console.error("Error deleting Firebase Auth user:", error);
          // If user is already deleted or deletion fails, that's okay
          // All data is already deleted
        }

        res.status(200).json({
          result: {
            success: true,
            message: "Account deleted successfully",
          },
        });
      } catch (error) {
        console.error("Error deleting user account:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to delete user account",
          },
        });
      }
    });

/**
 * Transfer payment to carrier
 *
 * This function handles payment transfers from shippers to carriers.
 * It charges the shipper's payment method and transfers funds to the
 * carrier's Stripe account.
 *
 * @param {Object} data - Transfer data
 * @param {string} data.carrierId - Carrier's user ID
 * @param {string} data.carrierStripeAccountId - Carrier's Stripe
 *   connected account ID (optional)
 * @param {string} data.carrierStripeCustomerId - Carrier's Stripe
 *   customer ID (optional)
 * @param {string} data.shipperId - Shipper's user ID
 * @param {string} data.shipperStripeCustomerId - Shipper's Stripe
 *   customer ID
 * @param {string} data.shipperPaymentMethodId - Shipper's payment
 *   method ID (optional)
 * @param {string} data.loadId - Load ID for this payment
 * @param {number} data.amount - Amount in cents
 * @param {string} data.currency - Currency code (default: 'usd')
 * @param {string} data.completionStatus - Delivery completion status
 * @returns {Object} Transfer result with transfer ID
 */
exports.transferPaymentToCarrier = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      // Handle preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token from header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        console.error("Missing or invalid Authorization header");
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated to transfer payment",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify the token and get user
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        console.error("Error verifying token:", error);
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const requestData = req.body.data || req.body;
        const {
          carrierId,
          carrierStripeAccountId,
          shipperId,
          shipperStripeCustomerId,
          shipperPaymentMethodId,
          loadId,
          amount,
          currency = "usd",
          completionStatus,
        } = requestData;

        // Validate required fields
        if (!carrierId || !shipperId || !loadId || !amount || amount <= 0) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Missing required fields: carrierId, " +
                  "shipperId, loadId, and amount are required",
            },
          });
          return;
        }

        // Verify shipper is making the request
        if (decodedToken.uid !== shipperId) {
          res.status(403).json({
            error: {
              status: "PERMISSION_DENIED",
              message: "Only the shipper can initiate payment transfers",
            },
          });
          return;
        }

        const stripe = getStripe();

        // Get or create shipper's Stripe customer ID if not provided
        let finalShipperStripeCustomerId = shipperStripeCustomerId;
        if (!finalShipperStripeCustomerId) {
          try {
            const shipperDoc = await admin.firestore()
                .collection("shippers")
                .doc(shipperId)
                .get();
            if (shipperDoc.exists) {
              const shipperData = shipperDoc.data();
              finalShipperStripeCustomerId = shipperData.stripeCustomerId;
            }

            // If still no customer ID, create one
            if (!finalShipperStripeCustomerId) {
              const customer = await stripe.customers.create({
                email: decodedToken.email,
                metadata: {
                  userId: shipperId,
                },
              });
              finalShipperStripeCustomerId = customer.id;

              // Save to Firebase
              await admin.firestore()
                  .collection("shippers")
                  .doc(shipperId)
                  .update({
                    stripeCustomerId: finalShipperStripeCustomerId,
                  });
            }
          } catch (error) {
            console.error(
                "Error getting/creating shipper Stripe customer:",
                error);
            res.status(400).json({
              error: {
                status: "INVALID_ARGUMENT",
                message: "Failed to get or create Stripe customer. " +
                    "Please try again or contact support.",
              },
            });
            return;
          }
        }

        // Get shipper's payment method if not provided
        // First check Firebase for stored payment method
        let paymentMethodId = shipperPaymentMethodId;
        if (!paymentMethodId) {
          try {
            const shipperDoc = await admin.firestore()
                .collection("shippers")
                .doc(shipperId)
                .get();
            if (shipperDoc.exists) {
              const shipperData = shipperDoc.data();
              paymentMethodId = shipperData.defaultPaymentMethodId;
            }
          } catch (error) {
            console.error("Error getting payment method from Firebase:", error);
          }
        }

        // If still no payment method, check Stripe customer
        if (!paymentMethodId && finalShipperStripeCustomerId) {
          try {
            const customer = await stripe.customers.retrieve(
                finalShipperStripeCustomerId);
            paymentMethodId = customer.invoice_settings &&
                customer.invoice_settings.default_payment_method ?
                customer.invoice_settings.default_payment_method :
                null;
            // If still no payment method, get the first available one
            // Check for all payment method types, not just cards
            if (!paymentMethodId) {
              // First try cards
              let paymentMethods = await stripe.paymentMethods.list({
                customer: finalShipperStripeCustomerId,
                type: "card",
              });
              if (paymentMethods.data.length > 0) {
                paymentMethodId = paymentMethods.data[0].id;
              } else {
                // If no cards, try all payment methods
                paymentMethods = await stripe.paymentMethods.list({
                  customer: finalShipperStripeCustomerId,
                });
                if (paymentMethods.data.length > 0) {
                  paymentMethodId = paymentMethods.data[0].id;
                }
              }
            }
          } catch (error) {
            console.error("Error retrieving shipper payment method:", error);
            console.error("Customer ID:", finalShipperStripeCustomerId);
          }
        }

        if (!paymentMethodId) {
          console.error("No payment method found for shipper:", shipperId);
          console.error("Stripe Customer ID:", finalShipperStripeCustomerId);
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Shipper does not have a payment method set up. " +
                  "Please add a payment method in your account settings " +
                  "before releasing payment.",
            },
          });
          return;
        }

        // Step 1: Create a Payment Intent to charge the shipper
        // If carrier has Connect account, charge directly to it using
        // transfer_data. This avoids "insufficient funds" issue in test mode
        const paymentIntentParams = {
          amount: amount,
          currency: currency.toLowerCase(),
          customer: finalShipperStripeCustomerId,
          payment_method: paymentMethodId,
          confirm: true,
          description: `Payment for load ${loadId}`,
          automatic_payment_methods: {
            enabled: true,
            allow_redirects: "never",
          },
          metadata: {
            loadId: loadId,
            carrierId: carrierId,
            shipperId: shipperId,
            completionStatus: completionStatus || "complete",
            type: "carrier_payment",
          },
        };

        // If carrier has Connect account, charge directly to it
        if (carrierStripeAccountId) {
          paymentIntentParams.transfer_data = {
            destination: carrierStripeAccountId,
          };
        }

        const paymentIntent = await stripe.paymentIntents.create(
            paymentIntentParams);

        if (paymentIntent.status !== "succeeded") {
          res.status(400).json({
            error: {
              status: "PAYMENT_FAILED",
              message: `Payment intent status: ${paymentIntent.status}`,
            },
          });
          return;
        }

        // Step 2: Check if payment was charged directly to Connect account
        // If transfer_data was used, no separate transfer is needed
        let transferId = null;
        let transferError = null;

        if (carrierStripeAccountId) {
          // Check if payment was charged directly to Connect account
          const transferData = paymentIntent.transfer_data;
          if (transferData &&
              transferData.destination === carrierStripeAccountId) {
            // Payment was charged directly to Connect account -
            // no transfer needed
            transferId = paymentIntent.id;
            console.log(
                "Payment charged directly to Connect account:",
                carrierStripeAccountId);
          } else {
            // Fallback: Try to transfer (for backwards compatibility)
            // This should rarely happen if transfer_data was set correctly
            try {
              const transfer = await stripe.transfers.create({
                amount: amount,
                currency: currency.toLowerCase(),
                destination: carrierStripeAccountId,
                description: `Payment for load ${loadId}`,
                metadata: {
                  loadId: loadId,
                  shipperId: shipperId,
                  completionStatus: completionStatus || "complete",
                },
              });
              transferId = transfer.id;
            } catch (transferErr) {
              console.error("Transfer failed:", transferErr);
              transferError = transferErr.message || "Transfer failed";
              // Refund the payment
              try {
                await stripe.refunds.create({
                  payment_intent: paymentIntent.id,
                });
                console.log("Payment refunded due to transfer failure");
              } catch (refundError) {
                console.error("Error refunding payment:", refundError);
              }
            }
          }
        } else {
          // Carrier doesn't have connected account - refund payment
          transferError = "Carrier does not have a Stripe connected account " +
              "set up. Payment was not transferred.";
          try {
            await stripe.refunds.create({
              payment_intent: paymentIntent.id,
            });
            console.log("Payment refunded - carrier has no connected account");
          } catch (refundError) {
            console.error("Error refunding payment:", refundError);
          }
        }

        // Step 3: Get carrier name and load number for transfer record
        let carrierName = "Unknown Carrier";
        let loadNumber = null;

        try {
          // Get carrier name
          const carrierDoc = await admin.firestore()
              .collection("carriers")
              .doc(carrierId)
              .get();
          if (carrierDoc.exists) {
            const carrierData = carrierDoc.data();
            carrierName = (carrierData && carrierData.companyName) ||
                (carrierData && carrierData.displayName) ||
                (carrierData && carrierData.name) ||
                "Unknown Carrier";
          }
        } catch (error) {
          console.error("Error fetching carrier name:", error);
        }

        try {
          // Get load number
          const loadDoc = await admin.firestore()
              .collection("loads")
              .doc(loadId)
              .get();
          if (loadDoc.exists) {
            const loadData = loadDoc.data();
            loadNumber = loadData.loadNumber || loadData.load_id || null;
          }
        } catch (error) {
          console.error("Error fetching load number:", error);
        }

        // Step 4: Store transfer record in Firestore
        try {
          await admin.firestore().collection("transfers").add({
            carrierId: carrierId,
            carrierName: carrierName,
            shipperId: shipperId,
            loadId: loadId,
            loadNumber: loadNumber,
            amount: amount / 100, // Convert cents to dollars
            amountInCents: amount,
            currency: currency,
            completionStatus: completionStatus || "complete",
            stripePaymentIntentId: paymentIntent.id,
            stripeTransferId: transferId,
            status: transferId ? "completed" : "failed",
            error: transferError,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            completedAt: transferId ?
                admin.firestore.FieldValue.serverTimestamp() : null,
            succeededAt: transferId ?
                admin.firestore.FieldValue.serverTimestamp() : null,
          });
        } catch (firestoreError) {
          console.error("Error storing transfer record:", firestoreError);
          // Don't fail the request if Firestore write fails
        }

        // Also store payment intent in payment_intents collection
        // with carrier info
        try {
          await admin.firestore().collection("payment_intents").add({
            userId: shipperId,
            paymentIntentId: paymentIntent.id,
            amount: amount,
            currency: currency,
            status: paymentIntent.status,
            carrierId: carrierId,
            carrierName: carrierName,
            loadId: loadId,
            loadNumber: loadNumber,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            succeededAt: paymentIntent.status === "succeeded" ?
                admin.firestore.FieldValue.serverTimestamp() : null,
            metadata: {
              loadId: loadId,
              carrierId: carrierId,
              shipperId: shipperId,
              completionStatus: completionStatus || "complete",
              type: "carrier_payment",
            },
          });
        } catch (logError) {
          console.error("Error storing payment intent record:", logError);
          // Don't fail the request if logging fails
        }

        // Step 5: Update delivery confirmation with payment info
        // Only mark as released if transfer was successful
        if (transferId) {
          try {
            const confirmationQuery = await admin.firestore()
                .collection("delivery_confirmations")
                .where("loadId", "==", loadId)
                .limit(1)
                .get();

            if (!confirmationQuery.empty) {
              await confirmationQuery.docs[0].ref.update({
                paymentReleased: true,
                paymentReleasedAt:
                    admin.firestore.FieldValue.serverTimestamp(),
                paymentAmount: amount / 100,
                stripePaymentIntentId: paymentIntent.id,
                stripeTransferId: transferId,
              });
            }
          } catch (updateError) {
            console.error("Error updating delivery confirmation:", updateError);
            // Don't fail the request if update fails
          }
        }

        // Return response - success if transfer worked, warning if not
        if (transferId) {
          res.status(200).json({
            result: {
              success: true,
              transferId: transferId,
              paymentIntentId: paymentIntent.id,
              amount: amount / 100,
              currency: currency,
            },
          });
        } else {
          // Payment was charged but transfer failed - return warning
          res.status(200).json({
            result: {
              success: false,
              warning: true,
              message: transferError ||
                  "Payment was charged but transfer to carrier failed. " +
                  "Payment has been refunded.",
              paymentIntentId: paymentIntent.id,
              amount: amount / 100,
              currency: currency,
            },
          });
        }
      } catch (error) {
        console.error("Error transferring payment to carrier:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to transfer payment to carrier",
          },
        });
      }
    });

/**
 * Create Escrow Payment Intent
 *
 * Creates a Stripe Payment Intent with manual capture to hold funds
 * in escrow until POD verification and payment release.
 *
 * @param {Object} data - Escrow payment data
 * @param {number} data.amount - Amount in cents
 * @param {string} data.loadId - Associated load ID
 * @param {string} data.carrierId - Carrier receiving payment
 * @param {string} data.shipperId - Shipper making payment
 * @param {string} data.currency - Currency code (default: 'cad')
 * @returns {Object} Payment intent with client secret
 */
exports.createEscrowPaymentIntent = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const requestData = req.body.data || req.body;
        const {
          amount,
          loadId,
          carrierId,
          shipperId,
          currency = "cad",
        } = requestData;

        if (!amount || amount <= 0) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Amount must be greater than 0",
            },
          });
          return;
        }

        if (!loadId || !carrierId || !shipperId) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "loadId, carrierId, and shipperId are required",
            },
          });
          return;
        }

        // Verify shipper matches authenticated user
        if (decodedToken.uid !== shipperId) {
          res.status(403).json({
            error: {
              status: "PERMISSION_DENIED",
              message: "Shipper ID must match authenticated user",
            },
          });
          return;
        }

        // Verify carrier has Stripe Connect account
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(carrierId)
            .get();
        if (!carrierDoc.exists) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Carrier not found",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();
        const carrierStripeAccountId = carrierData &&
            carrierData.stripeAccountId;
        if (!carrierStripeAccountId) {
          res.status(400).json({
            error: {
              status: "FAILED_PRECONDITION",
              message: "Carrier does not have a Stripe account set up",
            },
          });
          return;
        }

        // Get or create shipper Stripe customer
        const shipperDoc = await admin.firestore()
            .collection("shippers")
            .doc(shipperId)
            .get();
        const shipperData = shipperDoc.data();
        let shipperStripeCustomerId = shipperData &&
            shipperData.stripeCustomerId;

        if (!shipperStripeCustomerId) {
          const stripe = getStripe();
          const customer = await stripe.customers.create({
            email: decodedToken.email,
            metadata: {
              userId: shipperId,
            },
          });
          shipperStripeCustomerId = customer.id;
          await admin.firestore()
              .collection("shippers")
              .doc(shipperId)
              .update({
                stripeCustomerId: shipperStripeCustomerId,
              });
        }

        // Create payment intent with manual capture
        const stripe = getStripe();
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amount,
          currency: currency.toLowerCase(),
          capture_method: "manual",
          customer: shipperStripeCustomerId,
          metadata: {
            loadId: loadId,
            carrierId: carrierId,
            shipperId: shipperId,
            type: "escrow",
            createdAt: new Date().toISOString(),
          },
          automatic_payment_methods: {
            enabled: true,
          },
        });

        // Store escrow payment record in Firestore
        await admin.firestore().collection("escrow_payments").add({
          loadId: loadId,
          carrierId: carrierId,
          shipperId: shipperId,
          paymentIntentId: paymentIntent.id,
          amount: amount,
          amountInDollars: amount / 100,
          currency: currency,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Log payment intent
        try {
          await admin.firestore().collection("payment_intents").add({
            userId: shipperId,
            paymentIntentId: paymentIntent.id,
            amount: amount,
            currency: currency,
            status: paymentIntent.status,
            loadId: loadId,
            carrierId: carrierId,
            type: "escrow",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              loadId: loadId,
              carrierId: carrierId,
              shipperId: shipperId,
              type: "escrow",
            },
          });
        } catch (logError) {
          console.error("Failed to log escrow payment intent:", logError);
        }

        res.status(200).json({
          result: {
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
          },
        });
      } catch (error) {
        console.error("Error creating escrow payment intent:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message ||
                "Failed to create escrow payment intent",
          },
        });
      }
    });

/**
 * Capture Escrow Payment
 *
 * Captures a held escrow payment and transfers funds to carrier
 * after POD verification.
 *
 * @param {Object} data - Capture data
 * @param {string} data.paymentIntentId - Stripe payment intent ID
 * @param {string} data.loadId - Associated load ID
 * @param {string} data.carrierId - Carrier receiving payment
 * @param {string} data.shipperId - Shipper releasing payment
 * @param {number} data.amount - Amount to release in cents
 * @param {string} data.completionStatus - Delivery completion status
 * @param {string} data.currency - Currency code (default: 'cad')
 * @returns {Object} Capture result with transfer ID
 */
exports.captureEscrowPayment = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        const requestData = req.body.data || req.body;
        const {
          paymentIntentId,
          loadId,
          carrierId,
          shipperId,
          amount,
          completionStatus = "complete",
          carrierName: providedCarrierName,
        } = requestData;

        if (!paymentIntentId || !loadId || !carrierId || !shipperId) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "paymentIntentId, loadId, carrierId, " +
                  "and shipperId are required",
            },
          });
          return;
        }

        // Verify shipper matches authenticated user
        if (decodedToken.uid !== shipperId) {
          res.status(403).json({
            error: {
              status: "PERMISSION_DENIED",
              message: "Shipper ID must match authenticated user",
            },
          });
          return;
        }

        // Get escrow payment record
        const escrowQuery = await admin.firestore()
            .collection("escrow_payments")
            .where("paymentIntentId", "==", paymentIntentId)
            .where("loadId", "==", loadId)
            .limit(1)
            .get();

        if (escrowQuery.empty) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Escrow payment not found",
            },
          });
          return;
        }

        const escrowData = escrowQuery.docs[0].data();
        if (escrowData.status !== "deposited") {
          res.status(400).json({
            error: {
              status: "FAILED_PRECONDITION",
              message: `Escrow payment status is ${escrowData.status}, ` +
                  "expected 'deposited'",
            },
          });
          return;
        }

        // Get carrier Stripe account
        const carrierDoc = await admin.firestore()
            .collection("carriers")
            .doc(carrierId)
            .get();
        if (!carrierDoc.exists) {
          res.status(404).json({
            error: {
              status: "NOT_FOUND",
              message: "Carrier not found",
            },
          });
          return;
        }

        const carrierData = carrierDoc.data();
        const carrierStripeAccountId = carrierData &&
            carrierData.stripeAccountId;
        if (!carrierStripeAccountId) {
          res.status(400).json({
            error: {
              status: "FAILED_PRECONDITION",
              message: "Carrier does not have a Stripe account set up",
            },
          });
          return;
        }

        const stripe = getStripe();

        // Retrieve payment intent to get actual amount
        const paymentIntent = await stripe.paymentIntents.retrieve(
            paymentIntentId);
        const actualAmount = amount || paymentIntent.amount;

        // Capture the payment intent
        const capturedIntent = await stripe.paymentIntents.capture(
            paymentIntentId,
            {
              amount_to_capture: actualAmount,
            });

        if (capturedIntent.status !== "succeeded") {
          res.status(400).json({
            error: {
              status: "PAYMENT_FAILED",
              message: `Payment capture status: ${capturedIntent.status}`,
            },
          });
          return;
        }

        // Transfer funds to carrier's Connect account
        let transferId = null;
        try {
          const transfer = await stripe.transfers.create({
            amount: actualAmount,
            currency: paymentIntent.currency,
            destination: carrierStripeAccountId,
            description: `Escrow release for load ${loadId}`,
            metadata: {
              loadId: loadId,
              shipperId: shipperId,
              paymentIntentId: paymentIntentId,
              completionStatus: completionStatus,
              type: "escrow_release",
            },
          });
          transferId = transfer.id;
        } catch (transferError) {
          console.error("Transfer failed:", transferError);
          // Refund the captured payment
          try {
            await stripe.refunds.create({
              payment_intent: paymentIntentId,
            });
            console.log("Payment refunded due to transfer failure");
          } catch (refundError) {
            console.error("Error refunding payment:", refundError);
          }
          res.status(400).json({
            error: {
              status: "TRANSFER_FAILED",
              message: "Failed to transfer funds to carrier. " +
                  "Payment has been refunded.",
            },
          });
          return;
        }

        // Update escrow payment status
        await escrowQuery.docs[0].ref.update({
          status: "released",
          releasedAt: admin.firestore.FieldValue.serverTimestamp(),
          transferId: transferId,
          completionStatus: completionStatus,
        });

        // Get carrier name if not provided
        let carrierName = providedCarrierName || "Unknown Carrier";
        if (!providedCarrierName) {
          try {
            const carrierDoc = await admin.firestore()
                .collection("carriers")
                .doc(carrierId)
                .get();
            if (carrierDoc.exists) {
              const carrierData = carrierDoc.data();
              carrierName = (carrierData && carrierData.companyName) ||
                  (carrierData && carrierData.displayName) ||
                  (carrierData && carrierData.name) ||
                  "Unknown Carrier";
            }
          } catch (error) {
            console.error("Error fetching carrier name:", error);
          }
        }

        // Store transfer record
        await admin.firestore().collection("transfers").add({
          carrierId: carrierId,
          carrierName: carrierName,
          shipperId: shipperId,
          loadId: loadId,
          amount: actualAmount / 100,
          amountInCents: actualAmount,
          currency: paymentIntent.currency,
          completionStatus: completionStatus,
          stripePaymentIntentId: paymentIntentId,
          stripeTransferId: transferId,
          status: "completed",
          type: "escrow_release",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update delivery confirmation
        try {
          const confirmationQuery = await admin.firestore()
              .collection("delivery_confirmations")
              .where("loadId", "==", loadId)
              .limit(1)
              .get();

          if (!confirmationQuery.empty) {
            await confirmationQuery.docs[0].ref.update({
              paymentReleased: true,
              paymentReleasedAt:
                  admin.firestore.FieldValue.serverTimestamp(),
              paymentAmount: actualAmount / 100,
              stripePaymentIntentId: paymentIntentId,
              stripeTransferId: transferId,
            });
          }
        } catch (updateError) {
          console.error("Error updating delivery confirmation:", updateError);
        }

        res.status(200).json({
          result: {
            success: true,
            transferId: transferId,
            paymentIntentId: paymentIntentId,
            amount: actualAmount / 100,
            currency: paymentIntent.currency,
          },
        });
      } catch (error) {
        console.error("Error capturing escrow payment:", error);
        res.status(500).json({
          error: {
            status: "INTERNAL",
            message: error.message || "Failed to capture escrow payment",
          },
        });
      }
    });

