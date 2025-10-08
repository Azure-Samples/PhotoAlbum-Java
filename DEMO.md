Repo: https://github.com/menxiao_microsoft/PhotoAlbum

Prep
1.	Run az login to log into your account / subscription
2.	Run ./azure-setup.sh
3.	Verify that .env is created with the correct information
a.	Resource group name
b.	SQL server name
4.	Run ./deploy-to-azure.sh. This will deploy the local app to Azure. It will not run, but this step is to “prime” your machine so that subsequent deploys go faster.
a.	Also, this sets up the container environment, which otherwise can take a few minutes to get up and running.
OR
1.	Run azd provision
2.	Run azd deploy
Demo
1.	Run locally (CTRL-F5)
2.	It works locally
3.	You can show the ACA app that you prepped, and show that it does not work when you try to upload a photo

Migration
1.	Run appmod (right click on project / modernize)
2.	Select Migrate to Azure (you may or may not have to hit enter in the chat …)
 
3.	Assessment report should complete with the following issues:
 
4.	First, run the Database one. The default solution (Migrate from SQL Server to Managed Identity Based Azure SQL Database) is fine.
5.	You are going to need to continue once. This is an opportunity to talk about progress / plan if you want. It will be a tab in the editor.
 
(note – this takes a bit of time … - note you can do “continue without vcs tasks” which causes us not to do a branch and commit (and therefore lose tracking) to speed things up.
6.	When it’s done, keep the changes.

7.	YOU CAN SKIP THIS but this changes more code then the previous one. Next, run the File System Management one. The default solution (Migrate from local file system to Azure Blob Storage) is fine.

8.	IF YOU ARE NOT USING AZD, BEFORE deploying, you need to make a manual update in appsettings.json for the database server and the blob server. the migration tool does not read the database server yet. So you hopefully have this copied from .env.
 
9.	Build

10.	Deploy with a prompt “Deploy the application to Azure”. This should cause it to run the deploy-to-azure.sh script OR use azd deploy (or the AZD MCP).
