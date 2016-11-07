## PluginWizard ##

<img src="plugin-builder-logo.jpg" width="48">

###Getting Started###
1. Download or clone the PluginWizard repository.

    ```
	git clone https://github.com/electric-cloud/PluginWizard.git
    ```

2. Copy to a new directory, say 'MyPlugin'.

    ```
	cp -r PluginWizard MyPlugin
    ```

3. Assign a version number to your plugin, e.g., 1.0.0. Edit
    META-INF/plugin.xml (key, version, label) with the name and version
    of your plugin.    

4. Setup the directory structure for your procedures as described [here][1].

5. Finally, zip up the files to create the plugin zip file.

    ```
	 cd MyPlugin
	 zip -r MyPlugin.zip ./*
    ```

6. Import the plugin zip file into your ElectricFlow server and promote it.  
     
Your plugin procedure is now available for use!

[1]: https://github.com/electric-cloud/Patterns/tree/master/LightningTalks/PluginWizard
