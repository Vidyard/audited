Audited 
=======

**Audited** (previously acts_as_audited) is an ORM extension that logs all changes to your models. Audited also allows you to record who made those changes, save comments and associate models related to the changes. Audited works with Rails 3.

This is forked from https://github.com/collectiveidea/audited

This fork adds transaction_ids to help bundle audits where it makes sense.
It also removes version numbers. 

It's only testing on SQL, not Mongomapper.
