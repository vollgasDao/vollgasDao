import { DataService } from './../services/data.service';
import { Component, OnInit } from '@angular/core';

@Component({
    selector: 'app-home-page',
    templateUrl: './home-page.component.html',
    styleUrls: ['./home-page.component.scss']
})
export class HomePageComponent implements OnInit {
    public gasPrice: string;

    constructor(private data: DataService) {}

    ngOnInit() {
        this.getGasPrice();
    }

    private async getGasPrice() {
        await this.data
            .gasPrice()
            .then(response => response.json())
            .then(data => (this.gasPrice = (data.average / 10).toFixed(2)));
    }
}
