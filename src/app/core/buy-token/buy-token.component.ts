import { MyContract } from './../services/contracts/contract.service';
import { MetaMaskProvider } from './../services/metaMask.service';
import { DataService } from './../services/data.service';
import { Component, OnInit, Inject } from '@angular/core';
import { FormControl, Validators } from '@angular/forms';

@Component({
    selector: 'app-buy-token',
    templateUrl: './buy-token.component.html',
    styleUrls: ['./buy-token.component.scss']
})
export class BuyTokenComponent implements OnInit {
    public buyTokenControl: FormControl = new FormControl(null, [
        Validators.required,
        Validators.min(1)
    ]);
    public redeemTokenControl: FormControl = new FormControl(null, [
        Validators.required,
        Validators.min(1)
    ]);
    public priceToPay: number;
    private avgGasPrice: number;
    public paypackEther: number;
    public avgPriceToString: string;

    constructor(
        private data: DataService
    ) // private metaMask: MetaMaskProvider,
    // private contract: MyContract
    {}

    async ngOnInit() {
        await this.getAvgGasPrice();
        this.buyTokenControl.valueChanges.subscribe(
            amount => (this.priceToPay = amount * (this.avgGasPrice * 3))
        );
        /*    this.redeemTokenControl.valueChanges.subscribe(
            amount => (this.paypackEther = amount * this.avgGasPrice)
        );
        if ('enable' in this.web3.currentProvider) {
            await this.web3.currentProvider.enable();
        }
        const accounts = await this.web3.eth.getAccounts();
        console.log(accounts); */
    }

    public async getAvgGasPrice() {
        await this.data
            .gasPrice()
            .then(response => response.json())
            .then(price => {
                this.avgPriceToString = (price.average / 10).toFixed(2);
                this.avgGasPrice = price.average / 10;
            });
    }

    public buyToken() {
        // console.log(this.metaMask);
    }

    public redeemToken() {}
}
