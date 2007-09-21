# --
# Kernel/System/Fred.pm - all fred core functions
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: Fred.pm,v 1.1 2007-09-21 07:51:06 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred - fred core lib

=head1 SYNOPSIS

All fred standard core functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;
    use Kernel::System::DB;
    use Kernel::System::Main;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
#    my $DBObject = Kernel::System::DB->new(
#        ConfigObject => $ConfigObject,
#        LogObject => $LogObject,
#    );
    my $MainObject = Kernel::System::Main->new(
        LogObject => $LogObject,
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject MainObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item DataGet()

Evaluate the several data of all fred modules and add them
on the FredModules reference.

    $BackendObject = $FredObject->DataGet(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub DataGet {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{FredModulesRef} || ref( $Param{FredModulesRef} ) ne 'HASH' ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need FredModulesRef!",
        );
        return;
    }
    if ( !$Param{HTMLDataRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need HTMLDataRef!",
        );
        return;
    }

    for my $ModuleName ( keys %{ $Param{FredModulesRef} } ) {
        # load backend
        my $BackendObject = $Self->_LoadBackend( ModuleName => $ModuleName );

        # get module data
        if ($BackendObject) {
            $BackendObject->DataGet(
                ModuleRef   => $Param{FredModulesRef}->{$ModuleName},
                HTMLDataRef => $Param{HTMLDataRef},
            );
        }
    }

    return 1;
}

=item _LoadBackend()

load a xml item module

    $BackendObject = $FredObject->_LoadBackend(
        ModuleName => $ModuleName,
    );

=cut

sub _LoadBackend {
    my $Self  = shift;
    my %Param = @_;
    my $BackendObject;

    # module ref
    if ( !$Param{ModuleName} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need ModuleName!" );
        return;
    }

    # use the caching mechanism later if required

    # check if object is cached
    #if ( $Self->{ 'Cache::_LoadXMLTypeBackend::' . $Param{Type} } ) {
    #    return $Self->{ 'Cache::_LoadXMLTypeBackend::' . $Param{Type} };
    #}

    # create new instance
    my $GenericModule = "Kernel::System::Fred::$Param{ModuleName}";
    if ( $Self->{MainObject}->Require($GenericModule) ) {
        $BackendObject = $GenericModule->new( %{$Self}, %Param, );
    }

    # cache object
    #if ($BackendObject) {
    #    $Self->{ '_LoadXMLTypeBackend::' . $Param{Type} } = $BackendObject;
    #}

    # return object
    return $BackendObject;
}

=item InsertLayoutObject()

FRAMEWORK-2.2 specific because there is no LayoutObject integration for
FRED in OTRS2.2 Layout.pm

    $FredObject->InsertLayoutObject();

=cut

# FRAMEWORK-2.2 specific because there is no LayoutObject integration for
# FRED in OTRS2.2 Layout.pm

sub InsertLayoutObject {
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . "/Kernel/Output/HTML/Layout.pm";

    if ( -l "$File" ) {
        die 'Can\'t manipulate Layout.pm because it is a symlink!';
    }

    my $InSub;
    open my $Filehandle, '<', $File  || die "FILTER: Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
        if ( $Line =~ /sub Print {/ ) {
            $InSub = 1;
        }
        if ( $InSub && $Line =~ /Debug => \$Self->{Debug},/ ) {
            push @Lines, "# FRED - manipulated\n";
            push @Lines, "                    LayoutObject => \$Self,\n";
            push @Lines, "# FRED - manipulated\n";
            $InSub = 0;
        }
    }
    close $Filehandle;

    open my $FilehandleII, '>', $File || die "FILTER: Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => 'FRED manipulated the Layout.pm!',
    );
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This Software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.1 $ $Date: 2007-09-21 07:51:06 $

=cut
