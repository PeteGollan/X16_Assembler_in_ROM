# Identifier Storage

This describes the internal identifier storage for the assembler. This is stored in a simple forward linked list.

| Offset | Purpose                                                      |
| ------ | ------------------------------------------------------------ |
| +0     | Offset to next, 0 indicates end of the list.                 |
| +1     | Hash: Sum of characters in identifier (upper case with bit 7 of last character set) |
| +2     | Type (see below)                                             |
| +3     | Flags: bit 7 set if undefined, otherwise unused              |
| +4,5   | Data bytes (value)                                           |
| +6     | Auxiliary Data byte (e.g. bank number)                       |
| +7     | Identifier in Upper Case, bit 7 of the last character is set. |
| +8     | Any extra data, e.g. the Macro body.                         |

------

*Paul Robson *(paul@robsons.org.uk)*

*Version 1.00 (11 March 2025)*