/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Plugin } from '@capacitor/core';

export interface HyperServicesPlugin extends Plugin {
  createHyperServices(clientId?: string, service?: string): Promise<void>;

  preFetch(payload: any): Promise<void>;

  initiate(payload: any): Promise<void>;

  process(payload: any): Promise<void>;

  terminate(): Promise<void>;

  isInitialised(): Promise<{ isInitialised: boolean }>;

  onBackPressed(): Promise<{ onBackPressed: boolean }>;

  isNull(): Promise<{ isNull: boolean }>;
}
