# HumanNameParser.perl
Is a Perl port of HumanNameParser.php. It returns the parts (leading initial, first, middle, last, suffix, and title) of a name from a string.

Based on the work of the original author Jason Priem (@jasonpriem) and the fork by David Gorges (@davidgorges).

It passes the original test suit from the PHP version as well as a couple of tests specific to the Perl version.

# Description
Takes human names of arbitrary complexity and various wacky formats like:

* J. Walter Weatherman 
* de la Cruz, Ana M. 
* James C. ('Jimmy') O'Dell, Jr.
* Dr. James C. ('Jimmy') O'Dell, Jr.

and parses out the:

- leading initial (Like "J." in "J. Walter Weatherman")
- first name (or first initial in a name like 'R. Crumb')
- nicknames (like "Jimmy" in "James C. ('Jimmy') O'Dell, Jr.")
- middle names
- last name (including compound ones like "van der Sar' and "Ortega y Gasset"), and
- suffix (like 'Jr.', 'III')
- title (like 'Dr.', 'Prof')

# Usage

```perl
use v5.10;
use HumanNameParser;

my $name = new HumanNameParser( name => "Alfonso ('Carlton') Lincoln Ribeiro Sr." );

say "Hello " . $name->getFirstName();
say "Your full name is: " . $name->getFirstName() . " " . $name->getMiddleName() . " " . 
                            $name->getLastName() . " " . $name->getSuffix();
```
