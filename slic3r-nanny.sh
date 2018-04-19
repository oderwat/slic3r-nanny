#!/usr/local/bin/php
<?php
if(count($argv)!=2) {
  die('No file given!'.PHP_EOL);
}
$fn=$argv[1];
$i=fopen($fn,"r");
$o=fopen($fn.'~working',"w");
$pause_at_layer=[];
$pause_at_z=[];
$bypass=false;
$simulate=false;
while(!feof($i)) {
  $line=trim(fgets($i));
  if(strlen($line)) {
    if($bypass) {
      fputs($o,$line.PHP_EOL);
      continue;
    }
    $m=[];
    if(preg_match("/^; Slic3r-Nanny: (.*)$/i",$line,$m)) {
      $cmd=trim($m[1]);
      $line.="!cmd";
      if(preg_match("/^pause at layer ([0-9]+) say \"(.*)\"$/i",$cmd,$m)) {
        $pause_at_layer[$m[1]]=$m[2];
        $line.="!pal";
      }
      if(preg_match("/^pause at z ([0-9.]+) say \"(.*)\"$/i",$cmd,$m)) {
        $pause_at_z[]=[$m[1],$m[2]];
        $line.="!paz";
      }
      $line.='; '.$cmd.PHP_EOL;
    } else if(preg_match("/^G1 Z([0-9.]+) F[0-9.]+ ; move to next layer \(([0-9]+)\)$/",$line,$m)) {
      // reporting layer progress
      $z=$m[1];
      $l=$m[2];
      $prep='';
      $app='';
      // check for adding pause at layer with wait for keypress
      if(isset($pause_at_layer[$l])) {
        $prep.="G1 X-20 Y190 ; Move head to wait position".PHP_EOL;
        $prep.="M0 ".$pause_at_layer[$l]." ; wait for button press".PHP_EOL;
      }
      foreach($pause_at_z as $idx=>$dat) {
        if($z>=$dat[0]) {
          $prep.="G1 X-20 Y190 ; Move head to wait position".PHP_EOL;
          $prep.="M0 ".$dat[1]." ; wait for button press".PHP_EOL;
          unset($pause_at_z[$idx]);
        }
      }
      $line=$prep.$line.$app;
    }
    fputs($o,$line.PHP_EOL);
  }
}
if(!$simulate) {
  unlink($fn);
  rename($fn.'~working',$fn);
}
