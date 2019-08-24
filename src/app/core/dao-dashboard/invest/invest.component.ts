import { FormControl, Validators } from '@angular/forms';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-invest',
  templateUrl: './invest.component.html',
  styleUrls: ['./invest.component.scss']
})
export class InvestComponent implements OnInit {
  public investControl: FormControl = new FormControl(null, [Validators.required]);
  public cashOutControl: FormControl = new FormControl(null, [Validators.required])
  constructor() { }

  ngOnInit() {
  }

}
