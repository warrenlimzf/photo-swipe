// OPTIONAL. The app works without this: StoreKit 2 checks purchases on the phone.
// Deploy it only if you want Apple to tell you about purchases, refunds and Family Sharing
// changes as they happen (App Store Server Notifications V2). Apple POSTs a signed JWS here;
// this verifies Apple's signature with Apple's own library and logs what happened.
// The app never calls this server, so the "Data Not Collected" privacy label still holds.
//
// Setup: docs/payments.md → "Optional: server notifications".

import { Environment, SignedDataVerifier, NotificationTypeV2 } from "@apple/app-store-server-library";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

// PLACEHOLDERS, set as Vercel environment variables (never commit real values):
const BUNDLE_ID = process.env.APP_BUNDLE_ID ?? "com.warrenlimzf.photoswipe";
const APP_APPLE_ID = Number(process.env.APP_APPLE_ID ?? "0"); // App Store Connect → App Information → Apple ID
const ENVIRONMENT = process.env.APP_STORE_ENV === "Production" ? Environment.PRODUCTION : Environment.SANDBOX;

// Apple's root certificates (AppleRootCA-G3.cer etc.), downloaded from apple.com/certificateauthority
// into server/certs/. Pinning them is what stops anyone else posting fake notifications.
function appleRoots(): Buffer[] {
  const dir = join(process.cwd(), "certs");
  return readdirSync(dir)
    .filter((f) => f.endsWith(".cer"))
    .map((f) => readFileSync(join(dir, f)));
}

let verifier: SignedDataVerifier | undefined;
function getVerifier() {
  verifier ??= new SignedDataVerifier(
    appleRoots(),
    true, // check revocation (OCSP)
    ENVIRONMENT,
    BUNDLE_ID,
    ENVIRONMENT === Environment.PRODUCTION ? APP_APPLE_ID : undefined,
  );
  return verifier;
}

export async function POST(request: Request): Promise<Response> {
  let signedPayload: string;
  try {
    ({ signedPayload } = (await request.json()) as { signedPayload: string });
  } catch {
    return new Response("bad request", { status: 400 });
  }

  try {
    const v = getVerifier();
    const note = await v.verifyAndDecodeNotification(signedPayload);
    const signedTx = note.data?.signedTransactionInfo;
    const tx = signedTx ? await v.verifyAndDecodeTransaction(signedTx) : undefined;

    // Only facts about the purchase: no names, emails or photos ever reach this server.
    console.log(JSON.stringify({
      type: note.notificationType,
      subtype: note.subtype,
      product: tx?.productId,
      transaction: tx?.originalTransactionId,
      storefront: tx?.storefront,
      price: tx?.price,
      currency: tx?.currency,
      revoked: tx?.revocationDate ? new Date(tx.revocationDate).toISOString() : undefined,
    }));

    if (note.notificationType === NotificationTypeV2.REFUND) {
      // The phone locks itself on its next refresh (Transaction.currentEntitlements drops the
      // refunded purchase). Hook an alert here if you want to hear about it.
    }
    return new Response("ok");
  } catch (err) {
    // A failed signature check: not from Apple. Answer non-2xx so Apple retries real ones.
    console.error("notification rejected", err);
    return new Response("unverified", { status: 401 });
  }
}
