import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from '@apple/app-store-server-library';
import type { JWSTransactionDecodedPayload, ResponseBodyV2DecodedPayload, StatusResponse } from '@apple/app-store-server-library';

export type VerifiedTransaction = {
  transactionId: string; originalTransactionId: string; productId: string;
  appAccountToken?: string; environment: string; expiresDate?: number;
  revocationDate?: number; purchaseDate?: number; signedDate?: number;
};
export interface AppStoreSignedDataVerifier {
  verifyTransaction(jws: string): Promise<VerifiedTransaction>;
  verifyNotification(jws: string): Promise<ResponseBodyV2DecodedPayload>;
  verifyRenewal(jws: string): Promise<Record<string, any>>;
}
export interface AppStoreServerClient { getAllSubscriptionStatuses(id: string): Promise<StatusResponse>; }

export class AppleOfficialVerifier implements AppStoreSignedDataVerifier {
  constructor(private readonly verifier: SignedDataVerifier) {}
  async verifyTransaction(jws: string): Promise<VerifiedTransaction> {
    const p = await this.verifier.verifyAndDecodeTransaction(jws);
    return { transactionId: String(p.transactionId), originalTransactionId: String(p.originalTransactionId), productId: String(p.productId), appAccountToken: p.appAccountToken, environment: String(p.environment), expiresDate: p.expiresDate, revocationDate: p.revocationDate, purchaseDate: p.purchaseDate, signedDate: p.signedDate };
  }
  verifyNotification(jws: string) { return this.verifier.verifyAndDecodeNotification(jws); }
  verifyRenewal(jws: string) { return this.verifier.verifyAndDecodeRenewalInfo(jws) as Promise<Record<string, any>>; }
}
export class AppleOfficialServerClient implements AppStoreServerClient {
  constructor(private readonly client: AppStoreServerAPIClient) {}
  getAllSubscriptionStatuses(id: string) { return this.client.getAllSubscriptionStatuses(id); }
}
export function createAppleClients(config: { key: string; keyId: string; issuerId: string; bundleId: string; appAppleId: number; rootCertificates: Buffer[]; environment: 'Sandbox'|'Production' }) {
  const environment = config.environment === 'Sandbox' ? Environment.SANDBOX : Environment.PRODUCTION;
  const verifier = new SignedDataVerifier(config.rootCertificates, true, environment, config.bundleId, config.appAppleId);
  return { verifier: new AppleOfficialVerifier(verifier), server: new AppleOfficialServerClient(new AppStoreServerAPIClient(config.key, config.keyId, config.issuerId, config.bundleId, environment)) };
}
