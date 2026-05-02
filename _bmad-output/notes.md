# Supply Dynamics
- a plot of land has an associated base generating function that generates a quantity of resource over time g(t), the raw quantity is scaled by the area of the land. so A*g(t)
- the yield over time is also impacted by the product of all productivity factors acting on that plot of land.  which defaults to 0 if the elements in the productivity factor set are <1
- workers get assigned to work the plot of land and they have a base productivity function themselves (which can be modified, will be determined later).  the total number of workers assigned to the plot of land will determine the overall potential productivity as the sum of the workers productivities per unit of land.  sum(p_i(w)) over i.  the total productivity relative to the application of the workers is capped at 1, so max(potential_productivity,1) call this p(w).. i.e., p(w) = max(sum(p_i(w)) over i,1)
- there can be other modifiers, or sources of productivity,p(s) of which w - i.e., the workers is a part of that possible set that attach to the land productivity and can also be removed.
- the overall resource produced which contributes to the supply is therefore:
    A*g(t)*product(p(s))
- this contributes to the supply of the resource at that location.  
- for simplicity, one resource can be produced for any given area of land.

# Workers
- workers get assigned via contract to a plot of land.  they get exp for working that land and this improves their productivity over time (up to a limit).  
- the contract is between them and the person that owns the land - who, in return, offers them a wage in exchange for their service.
- the workers need to **eat** and **sleep** which replenishes their productivity.  if they don't eat or sleep, their **productivity** gets debuffed on a daily cycle.
- there are other factors that could hurt their productivity, like overall **morale**.
- if hunger is low, and morale drops too low this should trigger a **hunger strike** - which is a crisis event that causes the workers stop working altogether and thus creates a productivity of each worker of 0.  
    - either there's no grain, no money to buy grain (or other food), or a combination of both
    - 


# Market
- at the end of the week, the sum total of the supply is transported to market for sale to a merchant.
    - marking this event creates an interactive point which could be disrupted
    - once passing a disruption check
    - move to the buy/sell transaction which has it's own dynamics motivated by supply and demand (demand dynamics will be discussed below)
    - for now, assume the chances of a buy/sell transaction is 100%
- merchant then sells to others that would purchase for use, e.g., a tavern keeper would purchase grain to brew beer and sell beer to their patrons.  sell grain to individuals (such as back to the workers, so they can make bread and eat to sustain themselves)
- on market day, the workers and other will transact with the merchant, with their own quantities demanded (prices will be determined after total quantity demanded is evaluated against supply)
- we have to assume there are multiple markets with their own supply and demand dynamics
    - there likely needs to be a consideration for whether prices in a non-local market is preferable and how consumers decide to travel to non-local markets to transact on market day.  we need some simple dynamics for consumers who can't get their supply needs met at the local market.
- workers purchase based on their assessment of needs on a weekly basis.


# Demand
- this dynamic is where I could use some help.  demand is usually utility curve driven - which may result from several factors.
- **storage** - a factor marking how much abundance of a particular resource there is.  this is driven by the merchant 


# Workers

- step one - are you employed?
EMPLOYED - do work
UNEMPLOYED - seek work
(JobMarket supply and demand will drive aspects of wages, maybe also how skilled the job is?)

so UNEMPLOYED needs a whole job market system

## Skills
the more a worker works they earn xp on their skills which applies bonuses to their productivity.

# Assets
plot of land needs it's on resource generating function, resource type, then composition based modifiers that are then part of the function set that determines the productivity of the asset.. have to decide where the productivity of the resource originates -- with the worker or does it stay with the resource?  likely with the worker so that it's clear that the worker maintains ownership of it when transporting to storage (or maybe designed later, tries to steal or obscond with it).  

we also need to explore "enterprises" which generate income and incur costs?  income comes from sales machinery (supply exposed to **markets** and costs we need to define types of costs.. lords taxes (i.e., a lord may let you work an enterprise on their land for a price, or you are a lord and have to kick taxes up to your higher lord), wages for any workers - say if you pay a merchant)

will need a valuation function for buying and selling assets.  a tracking system for when assets are destroyed or when enterprises in the form of a partnership are dissolved or undermined.

# Products
grain --> bread
    baker (merchant)? cost + skill + grain == bread
        sells bread to workers
grain --> beer
    tavern keeper (merchant) cost + skill + grain
        sells beer
            + morale

?? how does morale interact with safety -- safety should degrade morale - and safety can also interact with building appearance, more cracks in windows, trash in the street, etc. less light.  less saturation.

if morale is consistently low - an unsafe event can trigger?  need to think through these dynamics.

# traits
traits of people will act as modifiers that'll create signals for their behavior.  
    brave?  
    dishonest? ethical?
    diligent? 
    empathetic!  empathy will motivate certain behaviors

# opportunities
need to identify what events are marked as opportunities - with a type of opportunity?  maybe a hazard type as well?  something to delineate event checks and watchers that can choose an opportunity?

# needs
1. food, shelter (safety)
2. social - sense of belonging
    sense of belonging drives whether someone will leave an area, and whether they can
3. mental health - morale


# wants
1. wealth
2. status
3. influence
4. power

# Actor Aptitudes
we'll simplify our builds to only 3 aptitudes that'll influence skill XP via experience (i.e., doing activities / performing actions).  
- Athleticism - will affect strength, dexterity, those types of related skills.
- Charisma - will affect things like bartering prices and socializing (how well liked someone is)
- Intelligence


# new prototype
our prototype is going to start with (i.e., for the simulation bootstrap):
- 1 Region
- 1 Land Owner
- 1 Plot of Land
- 2 Workers
- 1 Merchant

for simulation, there will be 8 daily ticks, one weekly tick, we can eventually add monthly and yearly ticks.  8 daily ticks will be associated with early morning, mid morning, late morning, early afternoon, late afternoon, early evening, late evening, and the middle of the night.

instead of having routines tied to specific ticks -- we'll have certain behaviors tied to windows that'll we'll emit specific signals during certain ticks that'll kick off events.  for the prototype we'll have:
- Labor Market Window (LMW)
- Work Window (WW)
- Wholesale Market Window (WMW)
- Retail Market Window (RMW)

there won't be any survival mechanics in the prototype.  only these market windows firing.  LMW will fire late evening, WW will fire mid morning, WMW will fire on early morning on the weekly tick, RMW will fire after the wholesale market closes during that same tick.

these windows in some instances will propagate in some instances to change behavior states, e.g., when the work window fires it changes a worker's state to WORKING.  the Market windows that fire will trigger the market to run it's clearing function.  we'll need a signal to trigger the work window closing.  

the Land Owner, Workers, and Merchants are all Actors.  as in economic Actors.  an Actor has their own books or ledgers that keep track of how much coin they have and what else is in their inventory.  we'll call it something simple like Accounts or Ledger.  the Land Owner with have a LandPlot (which is a type of ProductionResource) in their Accounts, coin will be listed in their accounts.  There will also be Contracts in the Land Owners account, to keep track of the wage agreements that clear from the LaborMarket.

**Interests** are what drives economic behaviors of the market participants and an Actor can have all sorts of Interests.  When an Actor acquires a LandPlot in the sim bootstrap we'll also attach a ProductionInterest on that LandPlot.  the LandPlot is a type of ProductionResource that will contain attributes around the size of the land, what types of goods are producable, and the base productivity function of the resource types.  Our starting LandPlot will produce Grain and we can pick a base scalar value which is representative of the base units of Grain produce per unit of time worked.  This ProductionInterest will determine the supply of workers demanded by some function - which will then emit LaborContract to the LaborMarket.  

For Interests we'll need some sort of function that'll fire, let's say daily, at the beginning of the Labor Market Window, so that quantity of labor demanded can be established.  Workers that are unemployed are also subscribed to this LMW signal and they emit that they are looking for work.  Once all labor supply and demand has been called, the LaborMarket will clear - determine the wages to be paid per unit of work.  We'll get to how wages are determined but they will be driven by attributes of the Actor looking for work (and other factors which will be discussed).  We'll have to elicit details about how the LaborMarket clearing works - but LaborMarkets will be tied to a region.

Workers have a WorkingInterest, when we bootstrap the world, that interest is what emits the desire to work - I should've mentioned that sooner.  Merchants have a MercantileInterest and this will drive their desire to stock up on Inventory (in the prototype's case it'll be Grain) and they'll emit this desire for the moment on an early morning tick before any market window opens.  Each Actor will also have a GrainInterest which for the moment we'll trigger on the late evening tick, and this GrainInterest emits demand for grain to the RetailMarket.  When the Retail Market Window opens it'll will then trigger the RetailMarket (for Grain) which has kept track of the supply and demand and from whom to clear.  We can discuss Market clearing dynamics in more detail later.  

I think the very first prototype we may simply want to have print statements that confirm the signals fire properly and then bake in calculations and such.

I forgot to mention that when the work window closes -- workers transfer the supply from the resource they produced to the land owners accounts, then they will emit a payable to the landowner's contracts for the wages due.  on a separate signal, say weekly, the landowner disburses the wages owed, decrementing coin from their inventory.  

the land owner will emit supply to the WholesaleMarket and when the Wholesale Market Window opens, there will be a similar clearing event between them and the merchants.

I might've missed some things so please ask questions.

Success Criteria for the prototype
- workers gain employment
- work contracts in place
- workers work, produce resources, emit payables, get paid
- owners sell supply in the wholesale market
- workers buy supply in the retail market

let's define and stub all of the classes that need to be created (Actors, Markets, ProductionResources, etc.), and the simulation concepts needed (ticks, windows, etc.), the signal buses that need to be created, and highlight any clarifications needed.  