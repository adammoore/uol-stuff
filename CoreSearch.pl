######################################################################
#
#  Search core.ac.uk for "input_field"
#
######################################################################
#
#  __COPYRIGHT__
#
# Copyright 2018 Adam Vials Moore, University of Liverpool. All Rights Reserved.
#
# Based on latest_tool.pl University of Southampton
#
#  __LICENSE__
#
# Replace YYY with your repository ID
#
# Replace XXXXXXXX with your Core API Key
#
######################################################################

use EPrints;
use LWP::Simple;
use Data::Dumper;
use JSON;

use strict;
my $session = new EPrints::Session;
exit( 0 ) unless( defined $session );

our @eprints = ();
our $test_search = '"Blue Whale"';

my $searchroot_url = "https://core.ac.uk:443/api-v2/articles/search/repositories.id%3AYYY%20AND%20";

my $searchterms_url = "?page=1&pageSize=20&metadata=true&fulltext=false&citations=false&similar=false&duplicate=false&urls=false&faithfulMetadata=false&apiKey=XXXXXXXX";


our $search_term ;


my $ds = $session->dataset( "archive" );

my $citation = $session->config( "latest_tool_citation" );

my $max = 20;
my $mode = $session->param( "mode" );
$mode = "default" if( !defined $mode );
my $search_fields = [];
my $filters = [];
my $conf = $session->config( "latest_tool_modes", $mode );
my $show_conditions = 0;
my $number_to_get = 1;
if( defined $conf )
{
        foreach my $key (keys %{$conf} )
        {
                $citation = $conf->{"citation"} if( $key eq "citation" );
                if( $key eq "filters" )
                {
                        $search_fields = $conf->{"filters"};
                        $show_conditions = defined $conf->{"show_conditions"} ? $conf->{"show_conditions"} : 1;
                }
                $max = $conf->{"max"} if( $key eq "max" );
        }
}
my $search_term = $test_search;
my $input_value = $session->param( "input_field" );
if( $input_value )
{
        $search_term = $input_value;
}else { $search_term = "test";}
my $indexOffset = $session->param( "indexOffset" );
$indexOffset = 1 if !$indexOffset || $indexOffset =~ /\D/;
my $title;
        $title = $session->html_phrase(
                "cgi/CoreSearch:title"
        );

my $search = url_encode($search_term);

my $result = get ($searchroot_url . $search . $searchterms_url);


#print STDERR Dumper ($result);

my $core_items = decode_json ( $result );
foreach (@{ $core_items->{data} }) {
        my $eprint_id =(split /:/, $_->{oai})[2];
        push @eprints , $session->eprint( $eprint_id );
}


my $page = $session->make_doc_fragment();

 my $form = $session->render_form("get", "CoreSearch");
 my $input_field = $session->make_element(
                     "input",
                     name=> "input_field",
                     type=> "text",
                     id=> "provider-remote"
                     );
 $form->appendChild($input_field);
 my $submit_button = $session->make_element(
                        "input",
                        name=> "_action_core_search",
                        type=> "submit",
                        style=> "size:1em",
                        value=>"Search"
                        );
 $form->appendChild($submit_button);

  $page->appendChild( $form );

my $res_text =  $session->make_element(
                        "h2",
                        );

$res_text->appendChild( $session->make_text ("Search Results for your search: $search_term"));

if ($search_term ne 'test'){
 $page->appendChild( $res_text );

my $type = $session->get_citation_type( $ds, $citation );
my $container;
if( $type eq "table_row" )
{
        $container = $session->make_element( "table", class=>"ep_latest_tool_list" );
}
else
{
        $container = $session->make_element( "div", class=>"ep_latest_tool_list" );
}
$page->appendChild( $container );
my $n = 1;
#print STDERR Dumper (@eprints);
foreach my $item ( @eprints )
{

        my $row = $item->render_citation_link(
                $citation,
                n => [$n++, "INTEGER"] );
        if( $type eq "table_row" )
        {
                $container->appendChild( $row );
        }
        else
        {
                my $div = $session->make_element( "div", class=>"ep_latest_tool_result" );
                $div->appendChild( $row );
                $container->appendChild( $div );
        }
}
}
my $template = defined $conf->{template} ? $conf->{template} : "default";
$session->build_page( $title, $page, "latest_tool", undef, $template );
$session->send_page();

$session->terminate;
exit;

sub url_encode {
my $rv = shift;
$rv =~ s/([^a-z\d\Q.-_~ \E])/sprintf("%%%2.2X", ord($1))/geix;
$rv =~ tr/ /+/;
return $rv;
}

