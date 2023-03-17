Follow these steps in the Vivado to create a project with name "p1" in myproject directory:

Step 1: View list of Yasin IPs that was used in this project in the Help/IPs.txt in the current project or download and view Project revision history.

Step 2: Download and copy Yasin IPs to a folder (optional folder anywhere which we refer to it as "Yasin IP repository folder". )

Method A: add repository before creating project (before running build.tcl)

  Step 3: Copy the "Yasin IP repository folder" Path to the ip_repo.txt and save it.

  Step 4: Run build. tcl

    Method 1: Select "Run Tcl Script..." from the "Tools" menu and select build.tcl file.

    Method 2: Enter "source  F:/Project_Name/build.tcl" command in the Tcl Console

        Note: You can modify the address of build.tcl file in above command


Method B: add repository after creating project after running build.tcl)

  Step 3: Run build. tcl

    Method 1: Select "Run Tcl Script..." from the "Tools" menu

    Method 2: Enter "source  F:/Project_Name/build.tcl" command in the Tcl Console

        Note: You can modify the address of build.tcl file in above command

  Step 4: In the created project, open "IP Catalog" and right click in the IP Catalog Window.

  step 5: In the popup menu select " + Add Repository..." option and select Yasin IP repository folder.
