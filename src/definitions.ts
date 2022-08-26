export interface HyperServicesPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
