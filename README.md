littlebits-connector
====================

Connect [LittleBits devices](http://littlebits.cc/cloud) to Salesforce without code! Based on the **Apex LittleBits API** [here](https://github.com/afawcett/apex-littlebitsapi). Currently outputs to LittleBits devices when records in standard or custom objects are updated. Upcoming features to subscribe to LittleBits device output and run headless Flows!

- [LittleBits Project Opportunity Probabilty Indicator](http://littlebits.cc/projects/salesforce-littlebits-connector-opportunity-probability-indicator)
- [Introducing Salesforce LittleBits Connector Blog](http://andyinthecloud.com/2015/01/02/introducing-the-littlebits-connector-for-salesforce/)
- [Video Demo of Salesforce LittleBits Connector](https://www.youtube.com/watch?v=wFlkhZk6Yo8&feature=youtu.be)

Package Install
===============

You can install this connector as managed "AppExchange" package more easily.

Version 1.0 - Beta
------------------

**IMPORTANT NOTE:** This is a Beta status package, it still needs more work to work to make it more robust, work within platform limits and utilise new features of the platform at this time i don't have available to me. So for now please feel free to use in your demo orgs or sandboxes, have fun and give some feedback!

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
