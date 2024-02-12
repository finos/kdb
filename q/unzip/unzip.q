.finos.dep.include"../util/util.q"


// Utilities

// Read bytes from either a file or a byte vector.
// @param x hsym or bytes
// @param y offset
// @param z length
// @return z bytes from x, starting at y
.finos.unzip.priv.bytes:{$[-11h=t:type x;read1(x;y;z);4h=t;x y+til z;'`type]}

// Count bytes from either a file or a byte vector.
// @param x hsym or bytes
// @return count of bytes in x
.finos.unzip.priv.bcount:{$[-11h=t:type x;hcount;count]x}

// Split a subsection of data into fields.
// Starts from offset and takes sum fields entries, splitting them according.
//  to fields.
// fields is a dictionary of field names and widths.
// @param x fields
// @param y offset
// @param z data
// @return the split subsection of the vector
.finos.unzip.priv.split:{(key x)!(get sums prev x)cut z y+til sum x}

// Parse byte(s) into a "number" (i.e. byte, short, int, or long, depending on the length).
// @param x byte or bytes
// @return byte, short, int, or long
.finos.unzip.priv.parseNum:.finos.util.compose({$[1=count x;first;0x00 sv]x};reverse);

// Parse byte(s) into bits; N.B. output is reversed to make flag dicts more natural.
// @param x byte or bytes
// @return bool vector
.finos.unzip.priv.parseBits:.finos.util.compose(reverse;0b vs;.finos.unzip.priv.parseNum);

// Parse bytes into a (global) unix timestamp.
// @param x bytes
// @return timestamp
.finos.unzip.priv.parseUnixTime:.finos.util.compose(.finos.util.timestamp_from_epoch;.finos.unzip.priv.parseNum);

// Parse a range of data with a header.
// parser is a function of three arguments:
//  Its first argument will be (data;extra); extra is passed as :: if not
//   included.
//  Its second argument will be the starting index of the record to extract.
//  Its third argument will be the raw headers of the record, split and
//   labeled according to fields.
//  It should return (record;next index).
// parser will be called until it returns next index equal to length.
// @param x (parser;fields;extra)
// @param y data
// @param z length
// @return parsed records
// @see .finos.unzip.priv.split
.finos.unzip.priv.parse:{
  if[2=count x;
    x,:(::);
    ];

  f:{
    $[
      (z 1)=z 2;
        z;
      [
        h:.finos.unzip.priv.split[x 1;z 1]y;
        a:x[0][(y;x 2);(z 1)+sum x 1]h;
        (raze(first z;enlist a 0);a 1;z 2)]]};

  1_first f[x][y]over(enlist(enlist`)!enlist(::);0;z)}


// Constants

// Flag names for central directory & file data
.finos.unzip.priv.flags:.finos.util.list(
  `encrypted_file;
  `compression_option_1;
  `compression_option_2;
  `data_descriptor;
  `enhanced_deflation;
  `compressed_patched_data;
  `strong_encryption;
  `unused_7;
  `unused_8;
  `unused_9;
  `unused_10;
  `language_encoding;
  `reserved_12;
  `mask_header_values;
  `reserved_14;
  `reserved_15;
  )

// Flag names for internal file attributes
.finos.unzip.priv.flags_iat:.finos.util.list(
  `text;
  `reserved_01;
  `control_field_records_precede_logical_records;
  `unused_03;
  `unused_04;
  `unused_05;
  `unused_06;
  `unused_07;
  `unused_08;
  `unused_09;
  `unused_10;
  `unused_11;
  `unused_12;
  `unused_13;
  `unused_14;
  `unused_15;
  )

// Flag names for extra field 0x5455 (extended timestamp)
.finos.unzip.priv.flags_xfd_0x5455:.finos.util.list(
  `mtime;
  `atime;
  `ctime;
  `reserved_3;
  `reserved_4;
  `reserved_5;
  `reserved_6;
  `reserved_7;
  )

// Field names and widths for end-of-central-directory.
.finos.unzip.priv.wecd:.finos.util.dict(
  `sig;4; / end of central dir signature                                                   4 bytes (0x06054b50)
  `dnu;2; / number of this disk                                                            2 bytes
  `dcd;2; / number of the disk with the start of the central directory                     2 bytes
  `den;2; / total number of entries in the central directory on this disk                  2 bytes
  `ten;2; / total number of entries in the central directory                               2 bytes
  `csz;4; / size of the central directory                                                  4 bytes
  `cof;4; / offset of start of central directory with respect to the starting disk number  4 bytes
  `cln;2; / .ZIP file comment length                                                       2 bytes
  `cmt;0; / .ZIP file comment                                                              (variable size)
  )

// Field names and widths for ZIP64 end-of-central-directory locator.
.finos.unzip.priv.wecl64:.finos.util.dict(
  `sig;4; / zip64 end of central dir locator signature                                     4 bytes  (0x07064b50)
  `dcd;4; / number of the disk with the start of the zip64 end of central directory        4 bytes
  `cof;8; / relative offset of the zip64 end of central directory record                   8 bytes
  `tnd;4; / total number of disks                                                          4 bytes
  )

// Field names and widths for ZIP64 end-of-central-directory.
.finos.unzip.priv.wecd64:.finos.util.dict(
  `sig;4; / zip64 end of central dir signature                                             4 bytes (0x06064b50)
  `s64;8; / size of zip64 end of central directory record                                  8 bytes
  `ver;2; / version made by                                                                2 bytes
  `vrr;2; / version needed to extract                                                      2 bytes
  `dnu;4; / number of this disk                                                            4 bytes
  `dcd;4; / number of the disk with the start of the central directory                     4 bytes
  `den;8; / total number of entries in the central directory on this disk                  8 bytes
  `ten;8; / total number of entries in the central directory                               8 bytes
  `csz;8; / size of the central directory                                                  8 bytes
  `cof;8; / offset of start of central directory with respect to the starting disk number  8 bytes
  `xds;0; / zip64 extensible data sector                                                   (variable size)
  )

// Field names and widths for file data.
.finos.unzip.priv.wfd:.finos.util.dict(
  `sig;4; / local file header signature                                                    4 bytes  (0x04034b50)
  `ver;1; / version needed to extract                                                      2 bytes
  `os ;1; / ??
  `flg;2; / general purpose bit flag                                                       2 bytes
  `cmp;2; / compression method                                                             2 bytes
  `mtm;2; / last mod file time                                                             2 bytes
  `mdt;2; / last mod file date                                                             2 bytes
  `crc;4; / crc-32                                                                         4 bytes
  `csz;4; / compressed size                                                                4 bytes
  `usz;4; / uncompressed size                                                              4 bytes
  `nln;2; / file name length                                                               2 bytes
  `xln;2; / extra field length                                                             2 bytes
  )

// Field names and widths for central directory.
.finos.unzip.priv.wcd:.finos.util.dict(
  `sig;4; / central file header signature                                                  4 bytes  (0x02014b50)
  `ver;2; / version made by                                                                2 bytes
  `vrr;2; / version needed to extract                                                      2 bytes
  `flg;2; / general purpose bit flag                                                       2 bytes
  `cmp;2; / compression method                                                             2 bytes
  `mtm;2; / last mod file time                                                             2 bytes
  `mdt;2; / last mod file date                                                             2 bytes
  `crc;4; / crc-32                                                                         4 bytes
  `csz;4; / compressed size                                                                4 bytes
  `usz;4; / uncompressed size                                                              4 bytes
  `nln;2; / file name length                                                               2 bytes
  `xln;2; / extra field length                                                             2 bytes
  `cln;2; / file comment length                                                            2 bytes
  `dnu;2; / disk number start                                                              2 bytes
  `iat;2; / internal file attributes                                                       2 bytes
  `xat;4; / external file attributes                                                       4 bytes
  `lof;4; / relative offset of local header                                                4 bytes
  )

// Field names and widths for extra field.
.finos.unzip.priv.wxfd:.finos.util.dict(
  `id ;2; / header id                                                                      2 bytes
  `sz ;2; / data size                                                                      2 bytes
  )


// Private API

// Parse end-of-central-directory record.
// @param x bytes
// @return end-of-central-directory record
.finos.unzip.priv.pecd:{
  r:.finos.unzip.priv.split[.finos.unzip.priv.wecd;0]x;
  r:![r;();0b;{y!x y}[{(.finos.unzip.priv.parseNum;x)}'](key r)except`sig`cmt];
  r:update cmt:"c"$(neg cln)#x from r;
  r}

// Parse a central directory record.
// @param x (bytes;extra)
// @param y index
// @param z header
// @return (record;next index)
// @see .finos.unzip.priv.parse
.finos.unzip.priv.pcd:{
  e:x 1;
  x:x 0;

  / see e.g. https://unix.stackexchange.com/a/14727 for info about xat
  r:update
      {("i"$first x)%10}ver,
      {("i"$first x)%10}vrr,
      .finos.unzip.priv.flags!.finos.unzip.priv.parseBits flg,
      .finos.unzip.priv.parseNum cmp,
      {"v"$24 60 60 sv 1 1 2*2 sv'0 5 11 cut reverse .finos.unzip.priv.parseBits x}mtm,
      {.finos.util.ymd . 1980 0 0+2 sv'0 7 11 cut reverse .finos.unzip.priv.parseBits x}mdt,
      .finos.unzip.priv.parseNum csz,
      .finos.unzip.priv.parseNum usz,
      .finos.unzip.priv.parseNum nln,
      .finos.unzip.priv.parseNum xln,
      .finos.unzip.priv.parseNum cln,
      .finos.unzip.priv.parseNum dnu,
      .finos.unzip.priv.parseBits iat,
      .finos.unzip.priv.parseBits xat,
      .finos.unzip.priv.parseNum lof
    from z;

  r:update
      fnm:`$"c"$x y+til nln,
      xfd:x y+nln+til xln,
      cmt:"c"$x y+nln+xln+til cln
    from r;

  (r;exec y+nln+xln+cln from r)}

// Parse ZIP64 end-of-central-directory locator record.
// @param x bytes
// @return ZIP64 end-of-central-directory locator record
.finos.unzip.priv.pecl64:{
  r:.finos.unzip.priv.split[.finos.unzip.priv.wecl64;0]x;
  r:![r;();0b;{y!x y}[{(.finos.unzip.priv.parseNum;x)}'](key r)except`sig`cmt];
  r}

// Parse ZIP64 end-of-central-directory record.
// @param x bytes
// @return ZIP64 end-of-central-directory record
.finos.unzip.priv.pecd64:{
  r:.finos.unzip.priv.split[update xds:(count x)-56 from .finos.unzip.priv.wecd64;0]x;
  r:![r;();0b;{y!x y}[{(.finos.unzip.priv.parseNum;x)}'](key r)except`sig`xds];
  r}

// Parse an extra field record.
// @param x (bytes;extra)
// @param y index
// @param z header
// @return (record;next index)
// @see .finos.unzip.priv.parse
.finos.unzip.priv.pxfd:{
  / parse fixed-order, variable-length data
  / @param x ([]n;w;f)
  / @param y bytes
  / @return dict
  p:{{((count y)#x)@'y}[(x`n)!x`f](sums prev{(1+(sums y)?x)#y}[count y]x`w)cut y};

  e:x 1;
  x:x 0;

  r:update
      reverse id,
      .finos.unzip.priv.parseNum sz
    from z;

  d:(r`sz)#y _x;
  c:count d;

  r,:$[
    / ZIP64 extended information extra field
    0x0001~r`id;
      [
        k:.finos.util.table[`n`w`f](
          `usz;8;.finos.unzip.priv.parseNum;
          `csz;8;.finos.unzip.priv.parseNum;
          `lof;8;.finos.unzip.priv.parseNum;
          `dnu;4;.finos.unzip.priv.parseNum;
          );

        p[k]d];

    / Unix
    0x000d~r`id;
      [
        / fixed fields followed by a variable field
        k:.finos.util.table[`n`w`f](
          `atime;   4;.finos.unzip.priv.parseUnixTime;
          `mtime;   4;.finos.unzip.priv.parseUnixTime;
          `uid  ;   2;.finos.unzip.priv.parseNum;
          `gid  ;   2;.finos.unzip.priv.parseNum;
          `var  ;c-12;"c"$;
          );

        p[k]d];

    / Xceed unicode extra field ("NU")
    / parsing notes:
    /  appears to be either two shorts or a long, followed by a short of size, followed by UTF-16 text
    /  but first one/two fields are unknown
    0x554e~r`id;
      [
        .finos.log.warning"Xceed unicode extra field: unimplemented extra field; skipping";
        ()];

    / extended timestamp ("UT")
    0x5455~r`id;
      [
        / parse and remove flag byte
        f:.finos.unzip.priv.flags_xfd_0x5455!.finos.unzip.priv.parseBits first d;
        d:1_d;

        / check field size matches flag byte
        if[c<>1+4*$[`fd=e`context;sum f;`cd=e`context;f`mtime;'`domain];
          '`parse;
          ];

        k:.finos.util.table[`n`w`f](
          `mtime;4;.finos.unzip.priv.parseUnixTime;
          `atime;4;.finos.unzip.priv.parseUnixTime;
          `ctime;4;.finos.unzip.priv.parseUnixTime;
          );

        ((enlist`flg)!enlist f),p[k]d];

    / Info-ZIP Unicode Path ("up", UPath)
    0x7075~r`id;
    [
      k:.finos.util.table[`n`w`f](
        `ver;  1;.finos.unzip.priv.parseNum;
        `crc;  4;reverse;
        `unm;c-5;"c"$;
        );

      p[k]d];

    / Info-ZIP Unix (previous new) ("Ux")
    0x7855~r`id;
      $[
        not c; / central-header version (no data)
          ();
        [
          k:.finos.util.table[`n`w`f](
            `uid;2;.finos.unzip.priv.parseNum;
            `gid;2;.finos.unzip.priv.parseNum;
            );

          p[k]d]];

    / Info-ZIP Unix (new) ("ux")
    0x7875~r`id;
      [
        / check version
        if[1<>.finos.unzip.priv.parseNum 1#d;
          '`nyi;
          ];

        / check field size is consistent with data
        if[c<>3+last{r:x 1;x:x 0;s:first x;((1+s)_x;r+s)}over(1_d;0);
          '`parse;
          ];

        / pairs of size and data fields
        ((enlist`ver)!enlist .finos.unzip.priv.parseNum 1#d),.finos.unzip.priv.parseNum each`uid`gid!last{r:x 1;x:x 0;s:first x;x:1_x;$[s;(s _ x;r,enlist s#x);(x;r)]}over(1_d;())];

    [
      .finos.log.warning(-3!r`id),": unimplemented extra field id; skipping";
      ()]];

  (r;exec y+sz from r)}

// Apply extra field.
// Parse xfd into records and apply to parent record as appropriate.
// Currently, extra is used for context information, so that fields that
//  differ in the central directory and local file header (e.g. 0x5455,
//  extended timestamp ("UT")) can be parsed properly.
// @param x extra
// @param y record containing xln and xfd fields
// @return record with xfd parsed and other fields modified accordingly
.finos.unzip.priv.axfd:{
  .finos.log.debug"applying extra field";
  r:y;

  r:$[
    r`xln;
    [
      / parse extra field
      r:update{x[;`id]!x}.finos.unzip.priv.parse[(.finos.unzip.priv.pxfd;.finos.unzip.priv.wxfd;x);xfd;count xfd]from r;

      / if ZIP64 record, upsert
      r,:exec{$[not any i:0x0001~/:x[;`id];();1=sum i;2_x first where i;'`parse]}xfd from r;

      / if UPath record, validate and upsert
      if[0x7075 in key r`xfd;
        r:$[
          (.finos.util.crc32[0]string r`fnm)~0x00 sv r[`xfd;0x7075]`crc;
            r,(enlist`fnm)!enlist`$r[`xfd;0x7075]`unm;
          [
            .finos.log.warning"invalid unicode path record; skipping";
            r]];
        ];

      / ignore any other extra fields for now
      r];
    r];

  .finos.log.debug"done applying extra field";
  r}

// Parse a file data record.
// @param x (bytes;extra)
// @param y index
// @param z header
// @return (record;next index)
// @see .finos.unzip.priv.parse
.finos.unzip.priv.pfd:{
  e:x 1;
  x:x 0;

  r:update
      {("i"$first x)%10}ver,
      first os,
      .finos.unzip.priv.flags!.finos.unzip.priv.parseBits flg,
      .finos.unzip.priv.parseNum cmp,
      {"v"$24 60 60 sv 1 1 2*2 sv'0 5 11 cut reverse .finos.unzip.priv.parseBits x}mtm,
      {.finos.util.ymd . 1980 0 0+2 sv'0 7 11 cut reverse .finos.unzip.priv.parseBits x}mdt,
      .finos.unzip.priv.parseNum nln,
      .finos.unzip.priv.parseNum xln
    from z;

  if[r[`flg]`data_descriptor;
      / data descriptor
      r,:`crc`csz`usz!4 cut -12#x;
      ];

  r:update
      .finos.unzip.priv.parseNum csz,
      .finos.unzip.priv.parseNum usz
    from r;

  r:update fnm:`$"c"$x y+til nln from r;

  r:update xfd:x y+nln+til xln from r;

  if[(not r`xln)&any -1=r`csz`usz;
    '`parse;
    ];

  r:.finos.unzip.priv.axfd[(enlist`context)!enlist`fd]r;

  .finos.log.debug"extracting data"," ",string .z.P;
  r:update
      fdt:x y+nln+xln+til csz-12*flg`encrypted_file,
      enc:x y+nln+xln+til     12*flg`encrypted_file,
      dtd:{$[y;x z+til 4*3+0x504b0708~x z+til 4;0#x]}[x;flg`data_descriptor]y+nln+xln+csz
    from r;
  .finos.log.debug"done extracting data"," ",string .z.P;

  / TODO can this filter be applied any earlier?
  r:$[
    (e~(::))|(r`fnm)in e;
      [
        .finos.log.info"inflating ",string r`fnm;

        $[
          / no compression: copy
          0=r`cmp;update fdu:"c"$fdt from r;

          / deflate: reframe as gzip stream and inflate
          8=r`cmp;update fdu:"c"$(.Q.gz 0x1f8b0800000000000003,fdt,crc,4#reverse 0x00 vs usz mod prd 32#2)from r;

          '`nyi]];
      update fdu:""from r];

  (r;exec y+nln+xln+csz+count dtd from r)}

// Find offset of central directory signature in a zip vector.
// Assumes last match is valid; more sophisticated algos are possible,
//  but they can be implemented as needed.
// @param x bytes
// @return long
.finos.unzip.priv.ovcds:{
  last("c"$x)ss"c"$0x504b0506}

// Find offset of central directory signature in a zip file.
// Implemented via sliding four-byte read starting at end of file.
// Assumes last match is valid; more sophisticated algos are possible,
//  but they can be implemented as needed.
// @param x hsym
// @return long
.finos.unzip.priv.ofcds:{
  c:hcount x;
  r:{(not 0x504b0506~y 0)&x>=y 1}[c]{(read1(x;y-z 1;4);1+z 1)}[x;c]/(0x00000000;0);
  $[0x504b0506~r 0;1+c-r 1;0N]}

// Find offset of zip64 end of central directory locator signature in a zip vector.
// Assumes last match is valid; more sophisticated algos are possible,
//  but they can be implemented as needed.
// @param x bytes
// @return long
.finos.unzip.priv.ovecls64:{
  last("c"$y)ss"c"$0x504b0607}

// Find offset of zip64 end of central directory locator signature in a zip file.
// Implemented via sliding four-byte read starting at end of file.
// Assumes last match is valid; more sophisticated algos are possible,
//  but they can be implemented as needed.
// @param x hsym
// @return long
.finos.unzip.priv.ofecls64:{
  c:hcount x;
  r:{(not 0x504b0607~y 0)&x>y 1}[c]{(read1(x;y-z 1;4);1+z 1)}[x;c]/(0x00000000;0);
  $[0x504b0607~r 0;1+c-r 1;0N]}

// Extract one file from an archive using unzip(1).
// @param x hsym
// @param y sym
// @return character vector
.finos.unzip.priv.unzip_system:{
  f:hsym`$first system"mktemp";
  system"(unzip -p \"",(1_string x),"\" \"",(string y),"\" >",(1_string f),")";
  r:"c"$read1 f;
  hdel f;
  r}

// Perform various zip-related operations.
// Possible values for x, and expected z arg in each case:
//   `list: List files in an archive.
//     z: ignored
//   `unzip: Extract (specific file(s) from) an archive.
//     z: sym, sym vector, or (::) to unzip all files
// See https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT,
//  https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html,
//  https://fossies.org/linux/zip/proginfo/extrafld.txt, etc.
// @param x sym
// @param y hsym, character vector, or byte vector
// @param z see above
// @return dictionary of filenames and character vectors
.finos.unzip.priv.unzip:{
  if[not x in`list`unzip;
    '`domain;
    ];

  / accept chars
  if[10h=type y;
    y:"x"$y;
    ];

  / accept hsym and bytes
  if[$[-11h=t:type y;not":"=first string y;4h<>t];
    '`type;
    ];

  if[`unzip=x;
    if[not(11h=abs type z)|z~(::);
      '`domain;
      ];
    ];

  .finos.log.info"processing ",$[-11h=t;1_string y;"archive"];

  / get byte count
  c:.finos.unzip.priv.bcount y;

  / look for central directory signature
  cds:$[4h=t;.finos.unzip.priv.ovcds;.finos.unzip.priv.ofcds]y;
  if[null cds;
    '"no central directory signature";
    ];

  / parse end-of-central-directory record
  ecd:.finos.unzip.priv.pecd .finos.unzip.priv.bytes[y;cds;c-cds];

  / punt on multi-disk archives
  if[0<>ecd`dnu;'`nyi];
  if[0<>ecd`dcd;'`nyi];

  / bytes of central directory record
  cd:exec .finos.unzip.priv.bytes[y;cof;csz]from
    $[
      -1=ecd`cof; / zip64
        [
          / look for zip64 end of central directory locator signature
          ecls64:$[4h=t;.finos.unzip.priv.ovecls64;.finos.unzip.priv.ofecls64]y;
          if[null ecls64;
            '"no end of central directory locator";
            ];

          / parse zip64 end-of-central-directory locator record
          ecl64:.finos.unzip.priv.pecl64 .finos.unzip.priv.bytes[y;ecls64;c-ecls64];

          / parse zip64 end-of-central-directory record
          ecd64:.finos.unzip.priv.pecd64 .finos.unzip.priv.bytes[y;ecl64`cof;12+.finos.unzip.priv.parseNum .finos.unzip.priv.bytes[y;4+ecl64`cof;8]]];
      ecd];

  / check for empty zip
  if[not count cd;
      :$[
        `list=x;
          ([name:0#`]size:0#0Ni;timestamp:0#0Np);
        `unzip=x;
          $[
            -11h=type z;
              [
                .finos.log.error(string z),": file not found in archive";
                'z;
                ];
            11h=type z;
              [
                {.finos.log.error(string x),": file not found in archive"}each z;
                'first z;
                ];
            z~(::);
              ((0#`)!())];
        '`domain];
    ];

  / start of central directory
  scd:$[-1=ecd`cof;ecd64;ecd]`cof;

  / parse central directory
  .finos.log.debug"parsing central directory";
  cd:.finos.unzip.priv.parse[(.finos.unzip.priv.pcd;.finos.unzip.priv.wcd);cd;count cd];
  .finos.log.debug"done parsing central directory";

  / apply extra field
  cd:.finos.unzip.priv.axfd[(enlist`context)!enlist`cd]each cd;

  r:$[
    `list=x;
      [
        1!select name:fnm,size:usz,timestamp:mdt+mtm from cd];
    `unzip=x;
      [
        / calculate next offsets
        cd:update nof:scd^next lof from cd;

        / apply file filter, if any
        if[not z~(::);
          cd:select from cd where fnm in z;
          if[count e:exec(raze z)except fnm from cd;
            {.finos.log.error(string x),": file not found in archive"}each e;
            'first e;
            ];
          ];

        / parse file data
        fd:$[
          .finos.unzip.filescan;
            [
              / read file if neccesary
              if[-11h=type y;
                y:read1 y;
                ];

              / trim any leading garbage
              y:(exec min lof from cd)_y;

              / extract all files
              .finos.unzip.priv.parse[(.finos.unzip.priv.pfd;.finos.unzip.priv.wfd;z);y;scd-exec min lof from cd]];
          [
            / extract each file mentioned in the central directory
            f:{[w;x;y;z]
              h:.finos.unzip.priv.split[w;0].finos.unzip.priv.bytes[x;y`lof;sum w];
              first .finos.unzip.priv.pfd[(.finos.unzip.priv.bytes[x;y`lof;z-y`lof];::);sum w;h]};

            / assume the end of the last file is the beginning of the central directory
            / might be wrong if archive decryption header and/or archive extra data record are present?
            cd f[.finos.unzip.priv.wfd;y]'exec nof from cd]];

        r:exec fnm!fdu from fd;

        r:$[
          11h=type z;
            z#r;
          -11h=type z;
            r z;
          r];

        if[.finos.unzip.verify&-11h=type y;
          .finos.log.info"verifying";
          v:r~$[
            -11h=type z;
              .finos.unzip.priv.unzip_system[y]z;
            {y!x y}[y .finos.unzip.priv.unzip_system/:]key r];
          if[not v;
            break;
            '`parse;
            ];
          .finos.log.info"verified";
          ];
        r];
    '`domain];

  r}


// Public API

// Set to true to verify extraction against unzip(1).
// N.B. will not work if .finos.unzip.unzip is called from a thread.
// N.B. will not work in file scan mode.
.finos.unzip.verify:0b

// Set to true to extract files via file scan, rather than by using the
//  central directory.
// N.B. currently, will likely fail for data-descriptor-based archives
.finos.unzip.filescan:0b

// List files in an archive.
// @param x hsym, character vector, or byte vector
// @return table of filenames and file metadata
.finos.unzip.list:{.finos.unzip.priv.unzip[`list;x;::]}

// Unzip an archive.
// @param x hsym, character vector, or byte vector
// @return dictionary of filenames and character vectors
.finos.unzip.unzip:{.finos.unzip.priv.unzip[`unzip;x;::]}

// Unzip specific files from an archive.
// @param x hsym, character vector, or byte vector
// @param y sym vector
// @return dictionary of filenames and character vectors
.finos.unzip.unzip2:{.finos.unzip.priv.unzip[`unzip;x;y]}
