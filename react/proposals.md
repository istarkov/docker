Some things i can propose how to write components and make 
its easy to move `to-from` meteor in the future and now.

1) Read [this article from Dan Abramov](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)   
(*using this ideas i've moved my projects from flummox to redux in hours, not days.*)

This code https://github.com/plentiful/jobs/blob/master/app/client/components/job-table.cjsx is not reusable it's `smart` and `dumb`.
In MVC approach you can think about `smart` components as like about 'controllers`.

Have a look at any component in my public project.
[smart component example](https://github.com/istarkov/google-map-react-examples/blob/master/web/flux/components/examples/x_main/main_map_page.jsx)   
All this component do, 
is connect data (and subscribe to data changes) via `Connector` component to my `dumb` components.

And if in the future i need to change stores to minimongo storage, 
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

But imho there is more easy way (at first sight), all we need is to reuse [Redux](https://github.com/gaearon/redux) framework (it's really great). (I need to talk about with aclark or somebody like)

I'm not know meteor much, but it looks like we can move this `startMeteorSubscriptions` to redux action (with support of redux middleware which will call store update `onDataChange`), and move `getMeteorState` in the same middleware.   
* unified action will look like `subscribe('Players', players => players.find().fetch())`
* imho unified actions is not a good way so just `subscribePlayers()`
* action code will look like `subscribePlayers = () => ({type: MONGO_SUBSCRIPTION, table: 'players', fetch: players => players.find().fetch()})` or more simple
* the same is for updates etc - is just a flux actions
* the best is to create HOC over redux Connector with support of `subscribe` `unsubscribe` over Meteor subscriptions - so we can reuse all the code as we have or not Meteor at all.

3) It looks like there is no need in server rendering at all for `admin like` apps, 
so why not just to make meteor renders only simple html page with scripts generated with webpack.
We get modern build system - `webpack`, hot reloading etc... 
And it looks like that next react versions will support relay - and all data meteor features become useless. (*IMHO*)

4) Why redux - IMHO (i know and write on a lot amount of flux frameworks) it's the best, it allows to create any available flux framework with it, it's great and it's the child of two greatest react programmers - aclark (flummox creator) and gaearon (Dan Abramov - hot reload creator).

5) https://github.com/plentiful/jobs/blob/master/app/client/pages/edit-job.cjsx real fuck in render - 
  render: ->
    div {},
      c JobHeading, id: @props.params.id
      JobForm job: @state.job
why to call CreateElement for JobHeading and not for JobForm imho it's (я бы убивал за такой код :-) ) 


