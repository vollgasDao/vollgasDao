import { VoteComponent } from './core/dao-dashboard/vote/vote.component';
import { ClaimComponent } from './core/dao-dashboard/claim/claim.component';
import { BuyTokenComponent } from './core/buy-token/buy-token.component';
import { HomePageComponent } from './core/home-page/home-page.component';
import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DaoDashboardComponent } from './core/dao-dashboard/dao-dashboard.component';
import { InvestComponent } from './core/dao-dashboard/invest/invest.component';

const routes: Routes = [
    {
        path: '',
        component: HomePageComponent
    },
    {
        path: 'buy-token',
        component: BuyTokenComponent
    },
    {
        path: 'dao',
        component: DaoDashboardComponent
    },

    {
        path: 'dao/invest',
        component: InvestComponent
    },
    {
        path: 'dao/claim',
        component: ClaimComponent
    },
    {
        path: 'dao/vote',
        component: VoteComponent
    }
];

@NgModule({
    imports: [RouterModule.forRoot(routes)],
    exports: [RouterModule]
})
export class AppRoutingModule {}
