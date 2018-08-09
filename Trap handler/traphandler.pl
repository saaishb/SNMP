#!/usr/bin/perl
use Net::SNMP;
use DBI;
use NetSNMP::TrapReceiver;


my $val1;
my @some;
my $val2;
#create db##################################
my $driver   = "SQLite"; 
my $database = "Trap.db";
my $dsn = "DBI:$driver:$database";

my $tid = time();
my $tid2;
my $val3; 
my $dbh = DBI->connect($dsn, { RaiseError => 1 }) 
   or die $DBI::errstr;
#create table###################################
my $stmt = qq(CREATE TABLE IF NOT EXISTS th(DN TEXT NOT NULL,NS INT NOT NULL,NT INT NOT NULL,OS INT,OT INT););

my $rv = $dbh->do($stmt);


#listening############################################ 

sub my_receiver {
     

      foreach my $x (@{$_[1]}) { 
           
		if ("$x->[0]" eq ".1.3.6.1.4.1.41717.10.1"){
		 	$val1 =  $x->[1];	
		}
		elsif ("$x->[0]" eq ".1.3.6.1.4.1.41717.10.2"){
			$val2 = $x->[1];
		}      
	}
$val1 =~ s/\"//gs;





#selct and insert with conditions###################################################

my $sum=0;
$stmt = qq(SELECT DN,NS,NT,OS,OT from th;);
my $sth = $dbh->prepare( $stmt );
 $rv = $sth->execute() or die $DBI::errstr;


my @rows;
while (my $row = $sth->fetchrow_hashref()){push @rows ,$row}
if(@rows){#if there are no empty rows#####################
	$stmt = qq(SELECT DN,NS,NT,OS,OT from th;);
	my $sth = $dbh->prepare( $stmt );
	 $rv = $sth->execute() or die $DBI::errstr;

	while(my @row =$sth->fetchrow_array()) {
	
	if ($row[0] eq $val1){ #same device################
		
		$tid1 = $row[2];
		$stmt = qq(UPDATE th set NS="$val2", NT="$tid", OS="$row[1]", OT="$tid1" where DN="$row[0]";);
		$rv = $dbh->do($stmt) or die $DBI::errstr;
		$sum = $sum+1;
	}
	
	}
}else{ #empty rows##############
	$stmt = qq(INSERT INTO th (DN,NS,NT,OS,OT)
               VALUES ("$val1","$val2","$tid","$val2","$tid"));
		$rv = $dbh->do($stmt) or die $DBI::errstr;
		$sum = $sum+1;
}
if($sum==0){ #new device added
$stmt = qq(INSERT INTO th (DN,NS,NT,OS,OT)
               VALUES ("$val1","$val2","$tid","$val2","$tid"));
		$rv = $dbh->do($stmt) or die $DBI::errstr;
		$sum = $sum+1;
}

#check for sending traps


$stmt = qq(SELECT DN,NS,NT,OS,OT from th;);
$sth = $dbh->prepare( $stmt );
$rv = $sth->execute() or die $DBI::errstr;


my @array2=();
my @array3=();
my $l=0;
while(my @row =$sth->fetchrow_array()) { #fail condition
	if ($row[1]==3){
		push @array3,('.1.3.6.1.4.1.41717.20.1', OCTET_STRING,$row[0], '.1.3.6.1.4.1.41717.20.2',TIMETICKS,$row[2], '.1.3.6.1.4.1.41717.20.3',INTEGER,$row[3],'.1.3.6.1.4.1.41717.20.4',TIMETICKS,$row[4]);
	}

	

	elsif ($row[1]==2 && $row[3]!=3){#danger condition
		push @array2,('.1.3.6.1.4.1.41717.30.'.(($l*4)+1), OCTET_STRING,$row[0], '.1.3.6.1.4.1.41717.30.'.(($l*4)+2),TIMETICKS,$row[2], '.1.3.6.1.4.1.41717.30.'.(($l*4)+3),INTEGER,$row[3],'.1.3.6.1.4.1.41717.30.'.(($l*4)+4),TIMETICKS,$row[4]);
	$l = $l+1;

				}
		

}

push @array3,@array2;


#select credentials from setTrap table###############################################
$stmt = qq(SELECT * FROM st WHERE ID =(SELECT MAX(ID) FROM st););
$sth = $dbh->prepare( $stmt );
$rv = $sth->execute() or die $DBI::errstr;
@row =$sth->fetchrow_array();
#create session#########################################################

my ($session, $error) = Net::SNMP->session(
   -hostname  => $ARGV[0] || $row[1],
   -community => $ARGV[1] || $row[3],
   -port      => $row[2],      # Need to use port 162 
);

if (!defined($session)) {
   printf("ERROR: %s.\n", $error);
   exit 1;
}

#send trap#################################
$result = $session->trap(-varbindlist  => \@array3); 

if (!defined($result)) {
   printf("ERROR: %s.\n", $session->error());
} else {
   printf("Trap-PDU sent.\n");
}




  }

  NetSNMP::TrapReceiver::register("all", \&my_receiver) || 
    warn "failed to register our perl trap handler\n";

  print STDERR "Loaded the example perl snmptrapd handler\n";



