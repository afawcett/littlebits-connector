littlebits-connector
====================

Connect [LittleBits devices](http://littlebits.cc/cloud) to Salesforce without code! Based on the **Apex LittleBits API** [here](https://github.com/afawcett/apex-littlebitsapi). Currently outputs to LittleBits devices when records in standard or custom objects are updated. Upcoming features to subscribe to LittleBits device output and run headless Flows!

Package
=======

You can install this connector as managed "AppExchange" package more easily.

Version 1.0
-----------

This version supports **LittleBits Triggers** and allows you to output to a device from any custom or standard object based on a given field or fields changing. The percent and duration of the output can be driven by fields on the record. For example Opportunity object based on the Probability changing updates your device!

![LittleBitsTrigger](https://raw.githubusercontent.com/afawcett/littlebits-connector/master/images/LittleBitsTrigger.png)

Package Install Links [Production URL](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t240000004kmO), [Sandbox URL](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t240000004kmO)

**IMPORTANT NOTE:** This version does not validate the fields entered into the LittleBits Trigger definition, be careful to enter these accuratly, using the demo screenshot as a guide. The trigger submits an ApexJob in the background, if it is not sending output to your device, go to the Setup menu and check under Apex Jobs for any error messages.

Code
====

If you want to change the code and hopefully contribute back to this project you can deploy to the code to your development org by clicking the button below.

<a href="https://githubsfdeploy.herokuapp.com?owner=afawcett&repo=littlebits-connector">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>
