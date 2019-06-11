<?php
$file = $argv[1];
$packagexml = xml_to_array($file);
if(!empty($packagexml['ApexClass'])){
	foreach($packagexml['ApexClass']['members'] as $class){
		if (stripos($class, 'Test_') !== false) {
		    $test_classes[] = $class;
		}
		else{
			$test_classes[] = 'Test_'.$class;
		}
	}
}
if(!empty($packagexml['ApexTrigger'])){
	foreach($packagexml['ApexTrigger']['members'] as $trigger){
		$test_classes[] = 'Test_'.$trigger;
	}
}
echo implode(' ',array_unique($test_classes));

function xml_to_array($file){
	$package = array();
	$handle = fopen($file, "r");
	if ($handle) {
		
	    while (($line = fgets($handle)) !== false) {
	    	$line = htmlspecialchars($line);
	    	//echo $line;
			if (stripos($line, 'types') !== false) {

				$members = array();
			}
			if (stripos($line, 'members') !== false) {
				preg_match('~'.htmlentities('<members>').'(.*?)'.htmlentities('</members>').'~', $line, $match);
				$members[] = $match[1];
			}
			if (stripos($line, 'name') !== false) {
				preg_match('~'.htmlentities('<name>').'(.*?)'.htmlentities('</name>').'~', $line, $match);
				$package[$match[1]]['members'] = $members;
			}
		}

	    fclose($handle);
	}
	return $package;
}
?>