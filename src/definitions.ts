export interface HyperServicesPlugin {

  createHyperServices(clientId?: string, service?: string): Promise<void>;

  preFetch(payload: any): Promise<void>;

  initiate(payload: string): Promise<void>;

  process(payload: any): Promise<void>;

  terminate(): Promise<void>;

  isInitialised(): Promise<{ isInitialised: boolean }>;

  onBackPressed(): Promise<{ onBackPressed: boolean }>;

  isNull(): Promise<{ isNull: boolean }>;
}
