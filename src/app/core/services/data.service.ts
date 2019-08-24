import { Injectable } from '@angular/core';

@Injectable({
    providedIn: 'root'
})
export class DataService {
    constructor() {}
    public async gasPrice() {
        return fetch('https://ethgasstation.info/json/ethgasAPI.json');
    }
}
