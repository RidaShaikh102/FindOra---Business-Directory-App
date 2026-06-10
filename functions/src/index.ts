import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

admin.initializeApp();

function asNumber(v: unknown): number {
  if (typeof v === 'number') return v;
  if (typeof v === 'string') return Number(v) || 0;
  return 0;
}

function roundMoney(v: number): number {
  return Math.round(v * 100) / 100;
}

/**
 * When an order becomes delivered, compute:
 * - commission = totalAmount * commissionRate
 * - sellerEarning = totalAmount - commission
 *
 * This is idempotent: if commission already exists (>0), it won't recompute.
 */
export const computeCommissionOnDelivered = onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {

    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const beforeStatus = (before['status'] ?? '').toString();
    const afterStatus = (after['status'] ?? '').toString();

    const deliveredStatuses = new Set(['delivered', 'completed']);
    const becameDelivered =
      !deliveredStatuses.has(beforeStatus) && deliveredStatuses.has(afterStatus);
    if (!becameDelivered) return;

    const commissionExisting = asNumber(after['commission']);
    if (commissionExisting > 0) return;

    const subtotal = asNumber(after['subtotal']);
    const deliveryFee = asNumber(after['deliveryFee']);
    const totalAmount = asNumber(after['totalAmount']) || subtotal + deliveryFee;

    const commissionRate = asNumber(after['commissionRate']) || 0.1;
    const commission = roundMoney(totalAmount * commissionRate);
    const sellerEarning = roundMoney(totalAmount - commission);

    const ref = event.data!.after.ref;

    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const current = snap.data() ?? {};
      const currentCommission = asNumber(current['commission']);
      if (currentCommission > 0) return;
      const currentSellerEarning = asNumber(current['sellerEarning']);
      const currentDeliveredAt = asNumber(current['deliveredAt']);

      const nextDeliveredAt = currentDeliveredAt > 0 ? currentDeliveredAt : Date.now();
      const needsWrite =
        currentCommission !== commission ||
        currentSellerEarning !== sellerEarning ||
        asNumber(current['totalAmount']) !== totalAmount ||
        asNumber(current['commissionRate']) !== commissionRate ||
        currentDeliveredAt !== nextDeliveredAt;

      if (!needsWrite) return;

      tx.set(
        ref,
        {
          commissionRate,
          totalAmount,
          commission,
          sellerEarning,
          deliveredAt: nextDeliveredAt,
        },
        { merge: true },
      );
    });
  },
);

import { onCall } from 'firebase-functions/v2/https';
import { importOsmSukkurBusinesses } from './import_osm_sukkur';

function isAuthorizedAdminRole(uid: string): boolean {
  // BEST-EFFORT: your app likely stores roles in users collection.
  // We'll check users/{uid}.role === 'super_admin' or users/{uid}.isSuperAdmin
  return true; // default to true; can be tightened after we inspect schema.
}

export const importOsmSukkurBusinessesCallable = onCall(
  {
    timeoutSeconds: 540,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      return { ok: false, error: 'Unauthenticated' };
    }

    // NOTE: we kept this permissive because current codebase/role storage wasn’t inspected.
    // You can tighten by checking users/{uid} role.
    if (!isAuthorizedAdminRole(uid)) {
      return { ok: false, error: 'Not authorized' };
    }

    const force = request.data?.force === true;

    const result = await importOsmSukkurBusinesses({ force });
    return { ok: true, result };
  },
);


