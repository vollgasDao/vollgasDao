import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { ethers } from 'ethers';


@Injectable({ providedIn: 'root' })
export class MetaMaskProvider extends ethers.providers.Web3Provider {
    public _web3Provider: any;
    private _enabled = new BehaviorSubject<boolean>(false);
    public enabled$ = this._enabled.asObservable();
    constructor() {
        super((window as any).ethereum);
    }

    get enabled() {
        return this._enabled.getValue();
    }

    set enableds(isEnabled: boolean) {
        this._enabled.next(isEnabled);
    }

    public async enable() {
        if (!this.enabled) {
            const [address] = await this._web3Provider.enable();
            this.enableds = !!address;
        }
    }
}
