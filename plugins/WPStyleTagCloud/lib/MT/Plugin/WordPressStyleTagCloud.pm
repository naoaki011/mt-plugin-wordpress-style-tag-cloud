package MT::Plugin::WordPressStyleTagCloud;
use strict;

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub _hdlr_wp_style_tag_rank
{
	my ($ctx, $args) = @_;
	
	require MT::Entry;
#	require MT::Template::Context;
	require MT::Template::Tags::Tag;
	require MT::ObjectTag;
	use POSIX qw(floor);
	$args->{top} = 25 unless $args->{top} > 0;
	##Most of this code was shamelessly stolen from MT/Template/ContextHandlers.pm::_hdlr_tags
	my $smallest = ($args->{smallest} and $args->{smallest} > 0) || 8;
	my $largest = ($args->{largest} and ($args->{largest} > 0 and $args->{largest} > $smallest)) || 22;
	my $type = $args->{type} || MT::Entry->datasource;
	my (%blog_terms, %blog_args);
	    $ctx->set_blog_load_context($args, \%blog_terms, \%blog_args) 
	        or return $ctx->error($ctx->errstr);
#	my $mtversion = MT->product_version;
#    if ($mtversion < 5) {
#		my ($tags, $min, $max, $all_count) = MT::Template::Context::_tags_for_blog($ctx, \%blog_terms, \%blog_args, $type);
#		MT::Template::Context::_tag_sort($tags, 'rank');
#	} else {
		my ($tags, $min, $max, $all_count) = MT::Template::Tags::Tag::_tags_for_blog($ctx, \%blog_terms, \%blog_args, $type);
		MT::Template::Tags::Tag::_tag_sort($tags, 'rank');
#	}

	my @tags;
		if ($args->{top} >= scalar(@$tags))
		{
			@tags = @$tags[0 .. scalar(@$tags)-1];		
		}
		else
		{
			@tags = @$tags[0 .. $args->{top}-1];
			my $ctr = 0;
			foreach (@tags)
			{
				die ("sadfsadf " . $ctr++) if !defined($_);
			}
		}
	my $out = '<div>%s</div>';
	my $link_template = '<a style="font-size: %dpt" title="%d topics" class="tag-link-%d" href="%s">%s</a>';

	my @processed_tags;
	my $min = 0;
	foreach (@tags)
	{
		$ctx->stash('Tag', $_);
#		my $search_link = MT::Template::Context::_hdlr_tag_search_link($ctx, $args);
#		my $tcount = MT::Template::Context::_hdlr_tag_count($ctx, $args);
		my $search_link = MT::Template::Tags::Tag::_hdlr_tag_search_link($ctx, $args);
		my $tcount = MT::Template::Tags::Tag::_hdlr_tag_count($ctx, $args);
		die (defined($_) ? 'true' : 'false') if $tcount == 0;
		my $count = floor ((log($tcount)/log(10))*100);
		push (@processed_tags, 
				{ 
					name => $_->name, 
					count => $count, 
					id => $_->id,
					topic_count => $tcount,
					search_link => $search_link
				});
		if ($_ == $tags[$#tags])
		{
			$min = $count;
		}
	}
	#die ($processed_tags[0]->{count} . ' ' . $min);
	my $spread = $processed_tags[0]->{count} - $min;
	$spread = 1 if $spread == 0;
	my $font_spread = $largest - $smallest;
	my $font_step = $font_spread / $spread;

	#die ("$spread $font_spread $font_step");
	
	fisher_yates_shuffle(\@processed_tags);

	my $inner = '';
	foreach (@processed_tags)
	{
		my $processed_count = ($smallest + (($_->{count} - $min) * $font_step));
		my $line = sprintf($link_template, $processed_count, $_->{topic_count}, $_->{id}, $_->{search_link}, $_->{name});
		$inner .= $line . "\n";
	}
	sprintf($out, $inner);
}

1;

