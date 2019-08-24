import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HomePageComponent } from './core/home-page/home-page.component';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatInputModule } from '@angular/material/input';
import { BuyTokenComponent } from './core/buy-token/buy-token.component';
import { FlexLayoutModule } from '@angular/flex-layout';
import { MatDividerModule,  } from '@angular/material';
import { ReactiveFormsModule } from '@angular/forms';
import { DaoDashboardComponent } from './core/dao-dashboard/dao-dashboard.component';
import { InvestComponent } from './core/dao-dashboard/invest/invest.component';
import { VoteComponent } from './core/dao-dashboard/vote/vote.component';
import { ClaimComponent } from './core/dao-dashboard/claim/claim.component';

@NgModule({
    declarations: [
        AppComponent,
        HomePageComponent,
        BuyTokenComponent,
        DaoDashboardComponent,
        InvestComponent,
        VoteComponent,
        ClaimComponent,
    ],
    imports: [
        BrowserModule,
        AppRoutingModule,
        NoopAnimationsModule,
        FlexLayoutModule,
        MatIconModule,
        MatMenuModule,
        MatButtonModule,
        MatDividerModule,
        ReactiveFormsModule,
        MatInputModule,
        MatCardModule
    ],
    providers: [],
    bootstrap: [AppComponent]
})
export class AppModule {}
