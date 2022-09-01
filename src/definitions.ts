export interface HyperServicesPlugin {

  preFetch(payload: any): Promise<void>;

  createHyperServices(): Promise<void>;

  initiate(payload: string): Promise<void>;

  terminate(): Promise<void>;

  isInitialised(): Promise<boolean>;

  process(payload: any): Promise<void>;

  onBackPressed(): Promise<boolean>;

  isNull(): Promise<boolean>;
}
