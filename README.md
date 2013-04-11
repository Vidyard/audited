Audited 
=======

**Audited** (previously acts_as_audited) is an ORM extension that logs all changes to your models. Audited also allows you to record who made those changes, save comments and associate models related to the changes. Audited works with Rails 3.

This is forked from https://github.com/collectiveidea/audited

## The Fork
This fork adds transaction_ids to help bundle audits where it makes sense.
It also provides organization_ids to all the bundles to help find changes belonging to a organization but not a user.
It also adds the optional "restore" action -- to distinguish between a model that is created or restored.
And some other things. It's not like anyone is going to use this, since it was made for our specific use case...
