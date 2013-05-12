#####################
# iRecover - Magic File Parsing and File Viewing/Sorting/Recovery Tool
# 
# This tool provides a GUI interface using the Perl/Tk programming library 
# for forensics examiners to use when retreiving deleted files from an 
# image/ file partition under forensic investigation. Investigators can
# use this tool to selectively retrieve only certain kinds of files (text,
# images, video, audio, documents, etc.) for a quick overview of information
# or for recovery using the "icat" Sleuth Kit tool to actually go into the 
# image and select the files of interest to display
# 
# SUPPORTED FILESYSTEMS: As of this first version of iRecover, our script 
# offers support for the FAT and NTFS filesystems. With the FAT file
# system, we recommend running our script against relatively recent versions of
# FAT (FAT16 or FAT32 for example) And yes, we 
# understand how deliciously ironic it is that our tool is called iRecover
# and yet it does not offer support for HFS or HFS+ file systems :)
# In future updates, we hope to include support and testing for other kinds of
# filesystems (such as EXT2/3 and HFS filesystems). 
#
# SUPPORTED FILETYPES: These are based off of the output of the sorter script
# command that is includes as part of the Sleuth Kit set of forensics tools 
# Sorter groups filetypes together based on a common, shared category 
# description (jpeg and gif files under "images" for instance). The list
# of sorter categories currently defined and supported in our scripts are 
# based of off the already pre-defined categories. They are:
#	- images
#	- text
#	- data
#	- video
#	- audio
#	- compress
#	- crypto
#	- disk
#	- documents
#	- exec
#	- system
#	- unknown
# For more specific details on what kinds of file types fall into each category
# see the sorter man page.
# 
# The GUI comes with a handy viewing feature for displaying key information on
# the selected file retrieved which includes filename, location, and certain 
# metadata attributes such as file size and time of last modification. The last
# attribute is interesting when recovering deleted files as it helps give the
# investigator the time of deletion for the file being recovered.
# The user can also choose to retrieve only a subset of the discovered items
# for a given filetype. Rather than retrieving all of them which could 
# waste some space on disk especially if some of the uninteresting files are
# excessively large in terms of file size.
#
# The standard procedure for operating our tool is to first determine if you
# would like to retrieve a specific category of files (only 1 category as of
# version 1.0) holding certain file types or all of the files on the image. 
# After making a selection, the investigator should then select an image to 
# process. At any point in this selection, it is easy to revert changes back
# to their defaults by pressing the "clear" button. Otherwise, clicking the
# "find" button will go into the image and using a wide variety of sleuth kit
# tools (mmls, sorter, fls, istat) gather information and metadata on all the
# files that match the desired file type being searched for.
#
# After finding the files, the tool will then output the results in the below 
# Listbox. This Listbox will displaying the findings according to the column
# headings that are defined - these include the file's name, its size, its
# file path (relative to the image being analyzed), a brief description of the 
# file, and the time of last modification. It is possible to sort, resize, and
# move around these columns by clicking on the column headers and borders between
# each column. When you are ready to recover files, simply click on the files
# of interest (default is ALL files are selected) and then hit the "Recover"
# button. At any time, should you desire to delete the contents of the table,
# simply click the "Clear Entries" button or select another image that you would
# like to analyze (could be the same image again if you want ;)). This will
# remove the current listings from the listbox table.
#
# Once the recovery process starts, iRecover will proceed to create a directory 
# to store the recovered files in within the present directory from which the
# script is run from. iRecover will then carve out the files which the user has
# selected into the newly created directory using the "icat" command - the 
# carved file will retain the same name that appears for it on the image. Currently 
# for version 1.0, this recovery directory will take the name of the image as its
# directory name.
#
# NOTE: In future updates if so desired, we hope to be able to provide the user
# the option to create or specify directories to save file carving results to 
# (we feel this may help to better group and categorize files for later analysis
# in a similar vein of thought as the Foremost tool)
# 
# This tool determines the identity of the files contained on the image through
# the use of the header bytes (or file signatures) contained at the beginning
# and end of certain kinds of files. Many of the Sleuth Kit tools we've 
# employed in our script look for these "magic numbers" as they are also
# known as to properly identify the file (regardless of if the user tried 
# to mask the true filetype by modifying the file extension). Since our script
# is highly dependent on these tools, it is a requirement that our script be run 
# on a Unix based workstation where these tools are already pre-installed and part 
# of the workstation's PATH variable. Some Linux distros and LiveCDs come with all 
# the Sleuth Kit tools pre-installed and loaded. Examples of these types of distros 
# include Backtrack 5R3 and Kali Linux among many others. We have tested and debugged
# our script thoroughly on the Backtrack 5R3 distro, so we highly recommend
# using our tool for investigations on this distro. 
#
# Our GUI is built on top of the Perl/Tk framework and programming library
# so it is necessary that this programming library is present on your 
# Linux station. Normally, Perl is a given for any Linux machine nowadays but
# Tk may require a download and compilation from the CPAN library if it is not
# already present. Additionally, there are some add-on widget methods/modules
# that act as extensions to Tk and are not included in the regular Tk 
# library by default. Necessary extensions that need to be included at run-time
# are the Tk::MListbox and Tk::ProgressBar modules. For graphical appearances,
# we have included a custom designed header and footer GIFs that offer a nice 
# graphical representation of our tool. These should be included along with the
# script in whatevery directory you choose to save it in.
#
# We have tested and recommend that our script be executed from the command
# line. No options to the command line are necesary - all options and decisions
# shall be set within the parameters and options of our GUI. Because our script depends 
# inode metadata values, our script should not be used to perform file carving
# on memory images - only on file system images.
#
# Much deserved credit goes to:
# 	- Brian Carrier at <www.thesleuthkit.org> for the icat, mmls, sorter, fls, 
# 	and istat tools (tools which make this script possible)
# 	- Malcolm Beattie for allowing Tcl/Tk programming using the Perl framework
# 	- Hans Jorgen Helgensen for the Tk::Mlistbox widget extension which made it
# 	incredibly easy to sort, resize, and move columns around in the standard
# 	listbox widget.
#
# Authors of this script. Included are our email addresses for contacting,
# reporting of bugs, and other deficiencies discovered running our script
# against various kinds of forensic images.
# 	- Hassan Alsaffar (haa1358@rit.edu)
# 	- Andrew Bell (acb2432@rit.edu)
# 	- Leonardo Rubio (lxr6746@rit.edu)
#####################
