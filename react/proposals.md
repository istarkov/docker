Some things I can propose how to write components and make 
its easy to move `to-from` meteor in the future and now.

1) Read [this article from Dan Abramov](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)   
(*using this ideas I've moved my projects from flummox to redux in hours, not days.*)

This code https://github.com/plentiful/jobs/blob/master/app/client/components/job-table.cjsx is not reusable it's `smart` and `dumb`.
In MVC approach you can think about `smart` components as like about 'controllers`. (React is not MVC but it's easy to think about if you've used MVC)

Have a look at any component in my public project.
[smart component example](https://github.com/istarkov/google-map-react-examples/blob/master/web/flux/components/examples/x_main/main_map_page.jsx)   
All this component do, is connect data (and subscribe to data changes) via `Connector` component to my `dumb` components.

And if in the future I need to change stores to minimongo storage, 
all i need is to rewrite only `Connector` component and it's props, nothing else.

2) **Mixins are dead** - it's true, so don't use mixins for modern react code.
https://medium.com/@dan_abramov/mixins-are-dead-long-live-higher-order-components-94a0d2f9e750

If you are using mixins now - your code is already old.

But using `hoc` ideas we can simply rewrite this 
https://github.com/plentiful/jobs/blob/10dd0083383694f485d5f8c8e8c141f6ba425349/app/client/lib/react-factories.coffee and this
```
startMeteorSubscriptions: -> Meteor.subscribe 'JobTable'
getMeteorState: -> jobs: Jobs.findAndSort().fetch()
```
to simple `Connector` like component with minimongo subscriptions and other stuff.

But IMHO there is more easy way (at first sight), all we need is to reuse [Redux](https://github.com/gaearon/redux) framework (it's really great). 

I don't know Meteor much, but it looks like we can move this `startMeteorSubscriptions` to Redux action (with support of Redux middleware which will call store update `onDataChange`), and move `getMeteorState` in the same middleware.   
* unified action will look like `subscribe('Players', players => Players.find().fetch())`
* imho unified actions is not a good way so just `subscribePlayers()`
* action code will look like `subscribePlayers = () => ({type: MONGO_SUBSCRIPTION, table: 'players', fetch: players => Players.find().fetch()})` or more simple
* the same is for updates etc - is just a Flux actions
* the best is to create HOC over redux Connector with support of `subscribe` `unsubscribe` over Meteor subscriptions - so we can reuse all the code as we have or not Meteor at all.

3) It looks like there is no need in server rendering at all for `admin like` apps, 
so why not just to make meteor renders only simple html page with scripts generated with webpack.
We get modern build system - `webpack`, hot reloading etc... 
And it looks like that next react versions will support Relay - and all data Meteor features become useless. (*IMHO*)

4) Why Redux - IMHO (I know and write on a lot amount of Flux frameworks) it's the best, it allows to create any available Flux framework with it, it's great and it's the child of two greatest react programmers - @aclark (flummox creator) and @gaearon (Dan Abramov - hot reload creator).

5) https://github.com/plentiful/jobs/blob/master/app/client/pages/edit-job.cjsx real fuck in render - 
```  
render: ->
    div {},
      c JobHeading, id: @props.params.id
      JobForm job: @state.job
```
why to call `CreateElement` for `JobHeading` and not for `JobForm` IMHO it's an anti-patterb (я бы убивал за такой код (Шучу. Ваня) :-) ) 
Why to differntiate factory objects and class objects. This what i mean  https://gist.github.com/sebmarkbage/fcb1b6ab493b0c77d589

6) CoffeeScript is a nowhere way (it looks good one year ago, but now :-( ) - for now Coffee looks like a dead language, one of the way to make your controls great is to publush them in open source world, is your need that almost nobody understand your language? I know that you think about tests - no tests gives you that can give a real user code review.
(and tech is fast today - one year ago coffee was a real good choice, but not today)
for example render function above in modern js looks like
```javascript
render: () => 
    <div>
        <JobHeading id = {this.props.params.id} />
        <JobForm job = {this.state.job} />
    </div>
```
don't like `this` use spread
```javascript
const {id} = this.props.params;
```
This code is more readable than cofee version - for almost any developer.
(*for me this comma sign in Coffee "c JobHeading`,` id: @props.params.id" kills all 

As example can you explain in one fast sentence why this
```
div {},
  c JobHeading, id: @props.params.id
  JobForm job: @state.job
```
is normal coffee code and
this
```
div, 
  c JobHeading, id: @props.params.id
  JobForm job: @state.job
```
is not :-) 

7) React Meteor projects are also dead now - the most popular version supports React v0.13.0 (March 10, 2015), for example in my real work I never use projects like this. React and JS are so fast now - can you wait so long for observables support and many other features.
