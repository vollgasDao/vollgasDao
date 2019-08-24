import { Inject } from '@angular/core';
import { Component, OnInit } from '@angular/core';
import { WEB3 } from './core/services/web3.service';
import Web3 from 'web3';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
    constructor(@Inject(WEB3) private web3: Web3) {}
    async ngOnInit() {
        if ('enable' in this.web3.currentProvider) {
            await this.web3.currentProvider.enable();
        }
        const accounts = await this.web3.eth.getAccounts();
        console.log(accounts);
    }
}
