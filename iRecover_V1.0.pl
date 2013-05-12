#####################
# iRecover - File Viewing/Sorting/Recovery Tool
#
# See included README.txt file as part of this tool submission
# for much greater detail on the operationg of this tool
#####################

#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Pane;
use Tk::MListbox;
use Tk::ProgressBar;

####################
# Global variables #
####################

my $all_ftypes_chked = 0; #Checks if checkbutton for all types is selected -
			  #Used as boolean to find all files in an image
my @ftypes = ("","images","text","data", "video", "audio","compress","crypto","disk","documents","exec",
		"system","unknown");
			#List of supported filetypes to recover currently
my $type = "";  		#Holds file type to retrieve
my $image = ""; 		#Holds image to be searched

#Hashes and arrays used for finding and recovering files - utilized in both finding and recovering subroutines
my %fileNames; #file inode -> file Name
my @deletedFilesInodes;

my $stSector = 0; #store the first sector of the partition

#########################
#Create the GUI Window. #
#########################

#Perform Geometry Management and arrange how the interface looks. 
#Specify the fields which the user should provide input as well as widgets needed to perform desired tasks 
#(find and display files on the image, retrieve desired files, etc.)

my $mw = new MainWindow(-title => 'iRecover - File Recovery Tool', -background => 'tan'); # Main Window
$mw->geometry('800x630');
my $ent_frame = $mw -> Frame(-background => 'tan'); #Frame to hold Entry and optionmenu fields
my $end_frame = $mw -> Frame(-background => 'tan');

my $header = $mw->Photo(-file => 'header.gif');
$mw->Label(-image=>$header)-> grid(-row => 0, -column => 0, -sticky => 'ns');

my $footer = $mw->Photo(-file => 'footer.gif');
$mw->Label(-image=>$footer)-> grid(-row => 9, -column => 0, -sticky => 's');

# Entry Frame - Filetype Optionmenu Row
my $ftype_lbl = $ent_frame -> Label(-text=>"File Type ", -background => 'tan');

my $ftype_opts = $ent_frame -> Optionmenu(-options=>\@ftypes,
                                          -variable=>\$type,
                                          -background => 'wheat',
                                          -command=>sub {
                                                $all_ftypes_chked = 0 if ($all_ftypes_chked == 1);
                                                });

my $all_ftypes_chkbox = $ent_frame -> Checkbutton(-text=>" All",
                                                  -background => 'tan',
                                                  -variable=>\$all_ftypes_chked,
                                                  -command=>\&clearFtypeOpts);

# Entry Frame - Location of image to check
my $loc_lbl = $ent_frame -> Label(-text=>"Image to Search ", -background => 'tan');
my $loc_button = $ent_frame -> Button(-text=>"Open", -command=>\&selectImage, -background => 'wheat');
my $loc_txt = $ent_frame -> Label(-textvariable=>\$image, -background => 'wheat');

# Button for clearing entries/options and checkboxes selected
my $clear_button = $ent_frame -> Button(-text=>"Clear", -command=>\&clearEntries, -background => 'wheat');

# Button for looking for files contained on the image matching the proper filetype
my $find_button = $ent_frame -> Button(-text=>"Find", -command=>\&findFiles, -background => 'wheat');

# New Frame to hold the listings of files found on the image for the matching 
# filetype
my $findings_lbl = $ent_frame -> Label(-text=>"\nFile(s) Found", -background => 'tan', -borderwidth => '4');
my $findings_frame = $ent_frame -> Frame(-background => 'tan');

my $findings_cols = $findings_frame -> Scrolled('MListbox',
						-selectmode=>'extended',
			                        -background => 'floralwhite',
						-highlightbackground => 'tan',
						-width=>755,
						-height=>12,
						-takefocus=>1);
                        

$findings_cols->columnInsert('end', -text=>'File Name',
				    -width=>18,
				    -background => 'wheat');

$findings_cols->columnInsert('end', -text=>'File Size (in KB)',
				    -width=>13,
				    -background => 'tan');

$findings_cols->columnInsert('end', -text=>'File Path',
				    -width=>17,
                                    -background => 'wheat');

$findings_cols->columnInsert('end', -text=>'Last Modified Time',
                                    -width=>24, 
				    -background=>'tan');

$findings_cols->columnInsert('end', -text=>'Description',
				    -width=>31, 
				    -background=>'wheat');

# Button to clear findings result from the HListTable
my $clrfind_button = $end_frame -> Button(-text=>"Clear Results", -command=>\&clearResults, -background => 'wheat');

# Recover button to allow recovery of selected files from listings
my $recover_button = $end_frame -> Button(-text=>"Recover",-command=>\&recoverFiles, -background => 'wheat');

#Define progress bar to monitor recovery process (if it takes a while - sometimes it run pretty quick)
my $percent_done;
my $progress = $end_frame->ProgressBar(
		-width => 30,
		-from => 0,
		-to => 100,
		-blocks => 50,
		-colors => [0, 'green', 50, 'yellow', 80, 'red'],
		-variable => \$percent_done);

# Geometry Management - Entries frame
$ftype_lbl -> grid(-row=>3,-column=>0, -sticky=>'ew');
$ftype_opts -> grid(-row=>3,-column=>1,-sticky=>'ew');
$all_ftypes_chkbox -> grid(-row=>3,-column=>2, -sticky=>'ew');

$loc_lbl -> grid(-row=>4,-column=>0,-sticky=>'ew');
$loc_button -> grid(-row=>4,-column=>1,-sticky=>'ew');
$loc_txt -> grid(-row=>4,-column=>2,-sticky=>'ewns');

$ent_frame -> grid(-row=>4,-column=>0,-sticky=>'nsew');
$end_frame -> grid(-row=>7,-column=>0,-sticky=>'nsew');

# Geometry Management - First set of Buttons
$clear_button -> grid(-row=>5,-columnspan => 1,-column=>1);
$find_button -> grid(-row=>5,-columnspan => 1,-column=>2);

# Geometry Management - Findings
$findings_lbl -> grid(-row=>6,-column=>0,-columnspan=>4,-sticky=>'nsew');
$findings_cols -> grid(-row=>0,-column=>0,-columnspan=>4,-sticky=>'nsew');
$findings_frame -> grid(-row=>7,-column=>0,-columnspan=>4, -sticky=>'nsew'); 

# Geometry Management - Second set of Buttons
$clrfind_button -> grid(-row=>8,-columnspan=>1,-column=>1);
$recover_button -> grid(-row=>8,-columnspan=>1,-column=>2);
$progress -> grid(-row=>9,-columnspan=>2,-column=>1, -sticky=>'nsew');

MainLoop();

#### List of functions

# Resets entry and options fields back to their defaults
sub clearEntries {		
	$all_ftypes_chked = 0; 
	$type = "";
	$image = "";
	$ent_frame -> update;
}

# Triggered when checkbox is selected - depending if on/off, toggle the select
# all files boolean variable
sub clearFtypeOpts { 
	if ($all_ftypes_chked == 1) {
		$type = "";
	}
	$ent_frame -> update;
}

# Select image to search using Tk's getOpenFile method
sub selectImage {

	#Filetypes supported in our image selection window
	my $types = [		
		['Image Files',	['.dd', '.img', '.E01', '.AFF']],
		['All Files',	'*'		],
		];
	$image = $ent_frame->getOpenFile(-filetypes=> $types,
					 -defaultextension=>".dd",
					 -title=>"Select Image");
					 
	#Place double quotes around image filepath (in case path contains spaces)
	$image = qq/"$image\"/;
	
	# Clear out any previously occupied listings from prior images in the 
	# listbox
	$findings_cols->delete(0,'end');	
} 

# Finds files using the filetype the user specified
sub findFiles {
	
	#Flush certain Globally Available arrays prior to running them through 
	#this subroutine again
	@deletedFilesInodes=();
	for (keys %fileNames){
		delete $fileNames{$_};
	}

	#Do Error checking to make sure user has selected a filetype and 
	#image file
	if ($type eq "" && $all_ftypes_chked == 0) {
		$ent_frame -> messageBox(-title => 'Error!', 
	     	-message=>"Did not specify a file type to select (or all files)! Please select a file type.",
	     	-type=> 'OK', -default => 'OK');
	        return;
	}

	if ($image eq "") {
		$ent_frame -> messageBox(-title => 'Error!', 
				 -message=>"Did not specify an image file!\n",
				 -type=> 'OK', -default => 'OK');
		return;
	}
	
	#List of filesystems are script currently supports
	my @supportedFileSystem = ("FAT", "NTFS");

	foreach my $element (@supportedFileSystem)
	{
		#Get the image file system information (File System Type and Start Sector)
		my @mmlsOutput;
                my $mmls;
                my $fs;
		$fs = `fsstat $image 2> /dev/null | grep "File System Type:"`;
		$fs =~ m/(.*) (.*)/;
                $fs = $2;
		if (not defined($fs)){
			$mmls = `mmls $image | grep $element`;
                        if (($mmls !~ m/^0/))
                        {
                                next;
                        }
                        else
                        {
                                push (@mmlsOutput, $mmls);

                                foreach my $m (@mmlsOutput)
                                {
                                        $m =~ m/(.*)  (.*)  (.*)  (.*)  (.*)  (.*)/;
                                        $stSector = $3;
                                        $fs = $6;
                                }
                         }

		}
                elsif ($fs eq "NTFS" or $fs eq "FAT12") {
                    $stSector = 0; 
		}

		#fls to list all deleted files 
		 chomp (my @flsOutput = `fls -rd -o $stSector $image`);
		 foreach (@flsOutput)
		 {
		      	if ($_ !~ m/^$/)
		        {
			 	$_ =~ m/(.*) (.*) (.*):\t(.*)/;
			 	if ($fs eq "NTFS")
                                {
                                        $3 =~ m/(.*)-(.*)-(.*)/;
                                        push (@deletedFilesInodes, $1);
                                        next;
                                }
				push (@deletedFilesInodes, $3);
		        }
		 }

		 #Get the metadat, File Type, File Size
		 chomp (my @sorterOutput = `sorter -l -o $stSector $image`);

		 my @fileInfo;
		 #Get the inodes of the deleted files
		 foreach (@sorterOutput)
		 {
		      	if ($_ !~ m/^$/)
		      	{
		 		if ($_ =~ m/^Image/)
		 		{
		    			$_ =~ m/(.*) (.*) (.*) (.*)/;
		    			push (@fileInfo, $4);
		 		}
		 		if ($_ =~ m/^Category/)
		 		{
		   			$_ =~ m/(.*): (.*)/;
		    			push (@fileInfo, $2);
		   			next;
		 		}
		 		next if ($_ =~ m/^Image/);
                                next if ($_ =~ m/^---/);
		 		last if ($_ =~ m/^------/);

       		 		push(@fileInfo, $_);
		      	}
		  }
		   	
	          #metadata
	 	  my $item;
		  my $cat;
		  my $name;
		  my $desc;  
		  my $size;
		  my $inode;
                  my $lastModTime;

		  my %fileTypes; #file inode -> filetype
		  my %filePath;  #file inode -> file path
		  my %fileSize;  #file inode -> file size
		  my %fileCat;   #file inode -> file category
                  my %fileLastModTime; #file inode -> file last Mod Time
		   
		  while (defined($item = shift @fileInfo))
		  {
		  	#Get the category for file type
			$cat = $item;

			#Get the filename
			$item = shift @fileInfo;
			$name = $item;

			#Get the file Type and metadata
			$item = shift @fileInfo;
			$desc = $item;

			#Get the inode associated with the file    
			$item = shift @fileInfo;
			if ($fs eq "NTFS")
                        {
                             $item =~ m/(.*)-(.*)-(.*)/;
                             $inode = $1;
                        }
                        else 
			{
		             $inode = $item;
			}

			#Store only deleted files info into the hashes
			foreach (@deletedFilesInodes)
			{ 
			      if ($_ eq $inode)
			      {
				 #get the file size based on inodes   
				 $size = `istat -o $stSector $image $inode | grep Size`;
				 $size =~ m/(.*) (.*)/;
				 $fileSize{$inode} = $2;

                                 if ($fs eq "NTFS")
				 {
                                        chomp(my @lastModTime = `istat -o $stSector $image $inode | grep "File Modified"`);
                                 	$lastModTime[0] =~ /\:.*?/;
                                        $lastModTime[0] = $';
                                        substr($lastModTime[0], 0, 1, '');
	                                $fileLastModTime{$inode} = $lastModTime[0];
                                 }
                                 else 
				 {
                                        $lastModTime = `istat -o $stSector $image $inode | grep Written`;
                                        $lastModTime =~ /\:.*?/;
                                        $lastModTime = $';
					substr($lastModTime, 0, 1, '');
                                        chop($lastModTime);
                                        $fileLastModTime{$inode} = $lastModTime;
                                 }

			 	#get the file type and description
			 	$fileTypes{$inode} = $desc;
				
            			#filename with full path  
				$filePath{$inode} = "/root/$name";
             			
			 	#filename
                                if ($fs ne "NTFS")
                                {
                                        $name = `istat -o $stSector $image $inode | grep Name`;
                                        $name =~ m/(.*) (.*)/;
	                                $fileNames{$inode} = $2;
                                }
                                else 
                                {
                                        $fileNames{$inode} = $name;
                                }
        
		         	$fileCat{$inode} = $cat;
		      	     }
	          	}	
               }
	       #Parse obtained file information and feed it to the Listbox 
	       #based on user preference 
	       foreach my $inode (sort keys %fileCat) 
	       { 
		   if ( $type eq $fileCat{$inode} ) 
		   {
			#Insert into MListbox here metadata results
			$findings_cols->insert("end", [[$fileNames{$inode}],[($fileSize{$inode}/1024.0)],[$filePath{$inode}],[$fileLastModTime{$inode}],[$fileTypes{$inode}]]);
	     	   }
		   elsif ( $all_ftypes_chked == 1 ) 
		   {
			$findings_cols->insert("end", [[$fileNames{$inode}],[$fileSize{$inode}],[($filePath{$inode}/1024.0)],[$fileLastModTime{$inode}],[$fileTypes{$inode}]]);
		   }	
	       }

	  $findings_cols->selectionSet(0, 'end'); 
	    
          last if $stSector eq "0";
	}
}

# Recover Selected Files that the user clicks in the Listbox
# Check for the entries selected by the user and carve out those
# entries using icat and the inode associated with that file.
sub recoverFiles {
	
	my @indicies = $findings_cols->curselection();
	
	#Get each indices respective elements. This will form an array of n 
	#number of columns for each row in the listbox
	my @elements;
	foreach my $index (@indicies) {
		push(@elements, $findings_cols->get($index));
	}
	
	# Prep a directory to store recovered files in the directory the user
	# runs this tool from.The directory will be named based on image name
	my @name_vals = split('/', $image);
	my $folder_name = $name_vals[scalar(@name_vals)-1];
	chop($folder_name);
	my $storedDir = $folder_name . "-OutputFiles";
	if ( system("ls -li | grep -i $storedDir") != 0) { #Dir not exist, 
							   #create a new one
		system("mkdir $storedDir");
	}

	# Get total number of elements to be recovered - this will serve as
	# an indication of the program's progres for the ProgressBar
	my $num_elements = scalar(@elements);
	
	#Iterate over the element array and determine which inode goes with 
	#which element's file name field
	#using the preconfigured/found fileName hash structure
	#Using the matching inode, proceed to carve the file out using icat
	
	for (my $i = 0; $i <= $num_elements; $i++) 
        {
		foreach my $inod (@deletedFilesInodes) 
                {
                    if (defined ($elements[$i]->[0]) and defined ($fileNames{$inod})) 
                    {
                        if ($elements[$i]->[0] eq $fileNames{$inod}) 
			{
				my $write = qq("$storedDir/$elements[$i]->[0]");
				system("icat -r -s -o $stSector $image $inod > $write");
		
		                #Show progress in the progress bar
				$percent_done = $progress/$num_elements;
				$mw->update;
			}
		     }
                     else {next;}
		}
	}
	$percent_done = 0; #for when next recovery procedure takes place
}
 
# Simply Delete Results from the central display table so user has the option to# search and retrieve contents from another image as well
sub clearResults {
	$findings_cols->delete(0,'end');	
}
