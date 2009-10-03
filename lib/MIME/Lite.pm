package MIME::Lite;
use strict;
require 5.004;    ### for /c modifier in m/\G.../gc modifier

=head1 NAME

MIME::Lite - low-calorie MIME generator

=head1 SYNOPSIS

Create and send using the default send method for your OS a single-part message:

    use MIME::Lite;
    ### Create a new single-part message, to send a GIF file:
    $msg = MIME::Lite->new(
        From     => 'me@myhost.com',
        To       => 'you@yourhost.com',
        Cc       => 'some@other.com, some@more.com',
        Subject  => 'Helloooooo, nurse!',
        Type     => 'image/gif',
        Encoding => 'base64',
        Path     => 'hellonurse.gif'
    );
    $msg->send; # send via default

Create a multipart message (i.e., one with attachments) and send it SMTP

    ### Create a new multipart message:
    $msg = MIME::Lite->new(
        From    => 'me@myhost.com',
        To      => 'you@yourhost.com',
        Cc      => 'some@other.com, some@more.com',
        Subject => 'A message with 2 parts...',
        Type    => 'multipart/mixed'
    );

    ### Add parts (each "attach" has same arguments as "new"):
    $msg->attach(
        Type     => 'TEXT',
        Data     => "Here's the GIF file you wanted"
    );
    $msg->attach(
        Type     => 'image/gif',
        Path     => 'aaa000123.gif',
        Filename => 'logo.gif',
        Disposition => 'attachment'
    );
    ### use Net:SMTP to do the sending
    $msg->send('smtp','some.host', Debug=>1 );

Output a message:

    ### Format as a string:
    $str = $msg->as_string;

    ### Print to a filehandle (say, a "sendmail" stream):
    $msg->print(\*SENDMAIL);

Send a message:

    ### Send in the "best" way (the default is to use "sendmail"):
    $msg->send;
    ### Send a specific way:
    $msg->send('type',@args);

Specify default send method:

    MIME::Lite->send('smtp','some.host',Debug=>0);

with authentication

    MIME::Lite->send('smtp','some.host',
       AuthUser=>$user, AuthPass=>$pass);

=head1 DESCRIPTION

In the never-ending quest for great taste with fewer calories,
we proudly present: I<MIME::Lite>.

MIME::Lite is intended as a simple, standalone module for generating
(not parsing!) MIME messages... specifically, it allows you to
output a simple, decent single- or multi-part message with text or binary
attachments.  It does not require that you have the Mail:: or MIME::
modules installed, but will work with them if they are.

You can specify each message part as either the literal data itself (in
a scalar or array), or as a string which can be given to open() to get
a readable filehandle (e.g., "<filename" or "somecommand|").

You don't need to worry about encoding your message data:
this module will do that for you.  It handles the 5 standard MIME encodings.

=head1 EXAMPLES

=head2 Create a simple message containing just text

    $msg = MIME::Lite->new(
        From     =>'me@myhost.com',
        To       =>'you@yourhost.com',
        Cc       =>'some@other.com, some@more.com',
        Subject  =>'Helloooooo, nurse!',
        Data     =>"How's it goin', eh?"
    );

=head2 Create a simple message containing just an image

    $msg = MIME::Lite->new(
        From     =>'me@myhost.com',
        To       =>'you@yourhost.com',
        Cc       =>'some@other.com, some@more.com',
        Subject  =>'Helloooooo, nurse!',
        Type     =>'image/gif',
        Encoding =>'base64',
        Path     =>'hellonurse.gif'
    );


=head2 Create a multipart message

    ### Create the multipart "container":
    $msg = MIME::Lite->new(
        From    =>'me@myhost.com',
        To      =>'you@yourhost.com',
        Cc      =>'some@other.com, some@more.com',
        Subject =>'A message with 2 parts...',
        Type    =>'multipart/mixed'
    );

    ### Add the text message part:
    ### (Note that "attach" has same arguments as "new"):
    $msg->attach(
        Type     =>'TEXT',
        Data     =>"Here's the GIF file you wanted"
    );

    ### Add the image part:
    $msg->attach(
        Type        =>'image/gif',
        Path        =>'aaa000123.gif',
        Filename    =>'logo.gif',
        Disposition => 'attachment'
    );


=head2 Attach a GIF to a text message

This will create a multipart message exactly as above, but using the
"attach to singlepart" hack:

    ### Start with a simple text message:
    $msg = MIME::Lite->new(
        From    =>'me@myhost.com',
        To      =>'you@yourhost.com',
        Cc      =>'some@other.com, some@more.com',
        Subject =>'A message with 2 parts...',
        Type    =>'TEXT',
        Data    =>"Here's the GIF file you wanted"
    );

    ### Attach a part... the make the message a multipart automatically:
    $msg->attach(
        Type     =>'image/gif',
        Path     =>'aaa000123.gif',
        Filename =>'logo.gif'
    );


=head2 Attach a pre-prepared part to a message

    ### Create a standalone part:
    $part = MIME::Lite->new(
        Type     =>'text/html',
        Data     =>'<H1>Hello</H1>',
    );
    $part->attr('content-type.charset' => 'UTF-8');
    $part->add('X-Comment' => 'A message for you');

    ### Attach it to any message:
    $msg->attach($part);


=head2 Print a message to a filehandle

    ### Write it to a filehandle:
    $msg->print(\*STDOUT);

    ### Write just the header:
    $msg->print_header(\*STDOUT);

    ### Write just the encoded body:
    $msg->print_body(\*STDOUT);


=head2 Print a message into a string

    ### Get entire message as a string:
    $str = $msg->as_string;

    ### Get just the header:
    $str = $msg->header_as_string;

    ### Get just the encoded body:
    $str = $msg->body_as_string;


=head2 Send a message

    ### Send in the "best" way (the default is to use "sendmail"):
    $msg->send;


=head2 Send an HTML document... with images included!

    $msg = MIME::Lite->new(
         To      =>'you@yourhost.com',
         Subject =>'HTML with in-line images!',
         Type    =>'multipart/related'
    );
    $msg->attach(
        Type => 'text/html',
        Data => qq{
            <body>
                Here's <i>my</i> image:
                <img src="cid:myimage.gif">
            </body>
        },
    );
    $msg->attach(
        Type => 'image/gif',
        Id   => 'myimage.gif',
        Path => '/path/to/somefile.gif',
    );
    $msg->send();


=head2 Change how messages are sent

    ### Do something like this in your 'main':
    if ($I_DONT_HAVE_SENDMAIL) {
       MIME::Lite->send('smtp', $host, Timeout=>60
           AuthUser=>$user, AuthPass=>$pass);
    }

    ### Now this will do the right thing:
    $msg->send;         ### will now use Net::SMTP as shown above

=head1 PUBLIC INTERFACE

=head2 Global configuration

To alter the way the entire module behaves, you have the following
methods/options:

=over 4


=item MIME::Lite->field_order()

When used as a L<classmethod|/field_order>, this changes the default
order in which headers are output for I<all> messages.
However, please consider using the instance method variant instead,
so you won't stomp on other message senders in the same application.


=item MIME::Lite->quiet()

This L<classmethod|/quiet> can be used to suppress/unsuppress
all warnings coming from this module.


=item MIME::Lite->send()

When used as a L<classmethod|/send>, this can be used to specify
a different default mechanism for sending message.
The initial default is:

    MIME::Lite->send("sendmail", "/usr/lib/sendmail -t -oi -oem");

However, you should consider the similar but smarter and taint-safe variant:

    MIME::Lite->send("sendmail");

Or, for non-Unix users:

    MIME::Lite->send("smtp");


=item $MIME::Lite::AUTO_CC

If true, automatically send to the Cc/Bcc addresses for send_by_smtp().
Default is B<true>.


=item $MIME::Lite::AUTO_CONTENT_TYPE

If true, try to automatically choose the content type from the file name
in C<new()>/C<build()>.  In other words, setting this true changes the
default C<Type> from C<"TEXT"> to C<"AUTO">.

Default is B<false>, since we must maintain backwards-compatibility
with prior behavior.  B<Please> consider keeping it false,
and just using Type 'AUTO' when you build() or attach().


=item $MIME::Lite::AUTO_ENCODE

If true, automatically choose the encoding from the content type.
Default is B<true>.


=item $MIME::Lite::AUTO_VERIFY

If true, check paths to attachments right before printing, raising an exception
if any path is unreadable.
Default is B<true>.


=item $MIME::Lite::PARANOID

If true, we won't attempt to use MIME::Base64, MIME::QuotedPrint,
or MIME::Types, even if they're available.
Default is B<false>.  Please consider keeping it false,
and trusting these other packages to do the right thing.


=back

=cut

use Carp ();
use FileHandle;

use vars qw(
  $AUTO_CC
  $AUTO_CONTENT_TYPE
  $AUTO_ENCODE
  $AUTO_VERIFY
  $PARANOID
  $QUIET
  $VANILLA
  $VERSION
  $DEBUG
);


# GLOBALS, EXTERNAL/CONFIGURATION...
$VERSION = '3.026';

### Automatically interpret CC/BCC for SMTP:
$AUTO_CC = 1;

### Automatically choose content type from file name:
$AUTO_CONTENT_TYPE = 0;

### Automatically choose encoding from content type:
$AUTO_ENCODE = 1;

### Check paths right before printing:
$AUTO_VERIFY = 1;

### Set this true if you don't want to use MIME::Base64/QuotedPrint/Types:
$PARANOID = 0;

### Don't warn me about dangerous activities:
$QUIET = undef;

### Unsupported (for tester use): don't qualify boundary with time/pid:
$VANILLA = 0;

$MIME::Lite::DEBUG = 0;

#==============================
#==============================
#
# GLOBALS, INTERNAL...

my $Sender = "";
my $SENDMAIL = "";

if ( $^O =~ /win32|cygwin/i ) {
    $Sender = "smtp";
} else {
    ### Find sendmail:
    $Sender   = "sendmail";
    $SENDMAIL = "/usr/lib/sendmail";
    ( -x $SENDMAIL ) or ( $SENDMAIL = "/usr/sbin/sendmail" );
    ( -x $SENDMAIL ) or ( $SENDMAIL = "sendmail" );
    unless (-x $SENDMAIL) {
        require File::Spec;
        for my $dir (File::Spec->path) {
            if ( -x "$dir/sendmail" ) {
                $SENDMAIL = "$dir/sendmail";
                last;
            }
        }
    }
    unless (-x $SENDMAIL) {
        undef $SENDMAIL;
    }
}

### Our sending facilities:
my %SenderArgs = (
  sendmail  => [$SENDMAIL ? "$SENDMAIL -t -oi -oem" : undef],
  smtp      => [],
  sub       => [],
);

### Boundary counter:
my $BCount = 0;

### Known Mail/MIME fields... these, plus some general forms like
### "x-*", are recognized by build():
my %Kno