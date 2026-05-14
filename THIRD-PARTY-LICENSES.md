# ParallelCluster Cookbook — Third-Party License Attributions

> Markdown rendering of `THIRD-PARTY-LICENSES.txt`. License texts are preserved verbatim inside fenced code blocks.

## Contents

- [openpmix; version 5.0.10](#openpmix-version-5010)
- [Python; version 3.14.2 (3.9.23 on AL2)](#python-version-3142-3923-on-al2)
- [enroot; version 3.4.1](#enroot-version-341)
- [requests; version 2.32.5](#requests-version-2325)
- [cookbook-line (grouped with 12 other entries sharing this license)](#cookbook-line-grouped-with-12-other-entries-sharing-this-license)
- [supervisor; version 4.3.0](#supervisor-version-430)
- [docutils; version 0.22.4](#docutils-version-0224)
- [jinja2; version 3.1.6](#jinja2-version-316)
- [click; version 8.1.7](#click-version-817)
- [Arm Performance Libraries; version 24.10](#arm-performance-libraries-version-2410)
- [Slurm; version 25.11.4-1](#slurm-version-25114-1)
- [stunnel; version 5.67](#stunnel-version-567)
- [MUNGE; version 0.5.18](#munge-version-0518)
- [gcc; version 11.3.0, 9.3.0](#gcc-version-1130-930)
- [MySQL; version 8.4.8 (8.0.39 on AL2, 8.0.45 on Ubuntu 24.04)](#mysql-version-848-8039-on-al2-8045-on-ubuntu-2404)
- [Intel MPI; version 2021.17 (2021.17.2.94)](#intel-mpi-version-202117-202117294)
- [setuptools; version 80.10.1](#setuptools-version-80101)
- [jsonschema; version 4.26.0](#jsonschema-version-4260)
- [efs-utils; version 2.4.0](#efs-utils-version-240)
- [tabulate; version 0.8.10](#tabulate-version-0810)
- [gdrcopy; version 2.5.2](#gdrcopy-version-252)
- [pyyaml; version 6.0.3](#pyyaml-version-603)
- [chevron; version 0.14.0](#chevron-version-0140)
- [libjwt; version 1.18.4 (1.17.0 on AL2)](#libjwt-version-1184-1170-on-al2)
- [Amazon DCV; version 2025.0-20103](#amazon-dcv-version-20250-20103)
- [Nvidia Driver; version 580.126.20 (550.127.08 on AL2)](#nvidia-driver-version-58012618-55012708-on-al2)
- [Cuda Samples; version 13.0 (12.4 on AL2)](#cuda-samples-version-130-124-on-al2)
- [Nvidia CUDA; version 13.0.2 (12.4.1 on AL2)](#nvidia-cuda-version-1302-1241-on-al2)
- [NVIDIA Fabric Manager (grouped with 2 other entries sharing this license)](#nvidia-fabric-manager-grouped-with-2-other-entries-sharing-this-license)
- [NVIDIA DCGM; version 4.5.1-1 (datacenter-gpu-manager-4-core + datacenter-gpu-manager-4-cuda13; 3.3.6-1 on AL2)](#nvidia-dcgm-version-451-1-datacenter-gpu-manager-4-core-datacenter-gpu-manager-4-cuda13-336-1-on-al2)
- [EFA Installer; version 1.47.0](#efa-installer-version-1470)
- [http-parser; version 2.9.4](#http-parser-version-294)


## openpmix; version 5.0.10

<https://github.com/openpmix/openpmix/>

```text
Most files in this release are marked with the copyrights of the
organizations who have edited them.  The copyrights below are in no
particular order and generally reflect members of the Open MPI core
team who have contributed code that may or may not have been ported
to PMIx. Per the terms of that LICENSE, we include the list here.
The copyrights for code used under license from other parties
are included in the corresponding files.

Copyright (c) 2004-2010 The Trustees of Indiana University and Indiana
                        University Research and Technology
                        Corporation.  All rights reserved.
Copyright (c) 2004-2010 The University of Tennessee and The University
                        of Tennessee Research Foundation.  All rights
                        reserved.
Copyright (c) 2004-2010 High Performance Computing Center Stuttgart,
                        University of Stuttgart.  All rights reserved.
Copyright (c) 2004-2008 The Regents of the University of California.
                        All rights reserved.
Copyright (c) 2006-2010 Los Alamos National Security, LLC.  All rights
                        reserved.
Copyright (c) 2006-2010 Cisco Systems, Inc.  All rights reserved.
Copyright (c) 2006-2010 Voltaire, Inc. All rights reserved.
Copyright (c) 2006-2011 Sandia National Laboratories. All rights reserved.
Copyright (c) 2006-2010 Sun Microsystems, Inc.  All rights reserved.
                        Use is subject to license terms.
Copyright (c) 2006-2010 The University of Houston. All rights reserved.
Copyright (c) 2006-2009 Myricom, Inc.  All rights reserved.
Copyright (c) 2007-2008 UT-Battelle, LLC. All rights reserved.
Copyright (c) 2007-2019 IBM Corporation.  All rights reserved.
Copyright (c) 1998-2005 Forschungszentrum Juelich, Juelich Supercomputing
                        Centre, Federal Republic of Germany
Copyright (c) 2005-2008 ZIH, TU Dresden, Federal Republic of Germany
Copyright (c) 2007      Evergrid, Inc. All rights reserved.
Copyright (c) 2008      Chelsio, Inc.  All rights reserved.
Copyright (c) 2008-2009 Institut National de Recherche en
                        Informatique.  All rights reserved.
Copyright (c) 2007      Lawrence Livermore National Security, LLC.
                        All rights reserved.
Copyright (c) 2007-2019 Mellanox Technologies.  All rights reserved.
Copyright (c) 2006-2010 QLogic Corporation.  All rights reserved.
Copyright (c) 2008-2010 Oak Ridge National Labs.  All rights reserved.
Copyright (c) 2006-2010 Oracle and/or its affiliates.  All rights reserved.
Copyright (c) 2009      Bull SAS.  All rights reserved.
Copyright (c) 2010      ARM ltd.  All rights reserved.
Copyright (c) 2010-2011 Alex Brick <bricka@ccs.neu.edu>.  All rights reserved.
Copyright (c) 2012      The University of Wisconsin-La Crosse. All rights
                        reserved.
Copyright (c) 2013-2019 Intel, Inc. All rights reserved.
Copyright (c) 2020-2023 Nanook Consulting. All rights reserved
Copyright (c) 2011-2014 NVIDIA Corporation.  All rights reserved.
Copyright (c) 2019-2023 Amazon.com, Inc. or its affiliates.  All Rights
                        reserved.
Copyright (c) 2022-2023 Triad National Security, LLC. All rights reserved

    * Package openpmix's source code may be found at:
      https://us-east-1-aws-
parallelcluster.s3.amazonaws.com/archives/dependencies/pmix/pmix-5.0.10.tar.gz

The following LICENSE pertains to both PMIx and any code ported
from Open MPI.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer listed
  in this license in the documentation and/or other materials
  provided with the distribution.

- Neither the name of the copyright holders nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

The copyright holders provide no reassurances that the source code
provided does not infringe any patent, copyright, or any other
intellectual property rights of third parties.  The copyright holders
disclaim any liability to any recipient for claims brought against
recipient by any third party for infringement of that parties
intellectual property rights.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

## Python; version 3.14.2 (3.9.23 on AL2)

<https://www.python.org/>

```text
Copyright © 2001 Python Software Foundation. All rights reserved.

    * Package Python's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/python/Python-3.14.2.tgz

A. HISTORY OF THE SOFTWARE
==========================

Python was created in the early 1990s by Guido van Rossum at Stichting
Mathematisch Centrum (CWI, see https://www.cwi.nl) in the Netherlands
as a successor of a language called ABC.  Guido remains Python's
principal author, although it includes many contributions from others.

In 1995, Guido continued his work on Python at the Corporation for
National Research Initiatives (CNRI, see https://www.cnri.reston.va.us)
in Reston, Virginia where he released several versions of the
software.

In May 2000, Guido and the Python core development team moved to
BeOpen.com to form the BeOpen PythonLabs team.  In October of the same
year, the PythonLabs team moved to Digital Creations, which became
Zope Corporation.  In 2001, the Python Software Foundation (PSF, see
https://www.python.org/psf/) was formed, a non-profit organization
created specifically to own Python-related Intellectual Property.
Zope Corporation was a sponsoring member of the PSF.

All Python releases are Open Source (see https://opensource.org for
the Open Source Definition).  Historically, most, but not all, Python
releases have also been GPL-compatible; the table below summarizes
the various releases.

    Release         Derived     Year        Owner       GPL-
                    from                                compatible? (1)

    0.9.0 thru 1.2              1991-1995   CWI         yes
    1.3 thru 1.5.2  1.2         1995-1999   CNRI        yes
    1.6             1.5.2       2000        CNRI        no
    2.0             1.6         2000        BeOpen.com  no
    1.6.1           1.6         2001        CNRI        yes (2)
    2.1             2.0+1.6.1   2001        PSF         no
    2.0.1           2.0+1.6.1   2001        PSF         yes
    2.1.1           2.1+2.0.1   2001        PSF         yes
    2.1.2           2.1.1       2002        PSF         yes
    2.1.3           2.1.2       2002        PSF         yes
    2.2 and above   2.1.1       2001-now    PSF         yes

Footnotes:

(1) GPL-compatible doesn't mean that we're distributing Python under
    the GPL.  All Python licenses, unlike the GPL, let you distribute
    a modified version without making your changes open source.  The
    GPL-compatible licenses make it possible to combine Python with
    other software that is released under the GPL; the others don't.

(2) According to Richard Stallman, 1.6.1 is not GPL-compatible,
    because its license has a choice of law clause.  According to
    CNRI, however, Stallman's lawyer has told CNRI's lawyer that 1.6.1
    is "not incompatible" with the GPL.

Thanks to the many outside volunteers who have worked under Guido's
direction to make these releases possible.


B. TERMS AND CONDITIONS FOR ACCESSING OR OTHERWISE USING PYTHON
===============================================================

Python software and documentation are licensed under the
Python Software Foundation License Version 2.

Starting with Python 3.8.6, examples, recipes, and other code in
the documentation are dual licensed under the PSF License Version 2
and the Zero-Clause BSD license.

Some software incorporated into Python is under different licenses.
The licenses are listed with code falling under that license.


PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2
--------------------------------------------

1. This LICENSE AGREEMENT is between the Python Software Foundation
("PSF"), and the Individual or Organization ("Licensee") accessing and
otherwise using this software ("Python") in source or binary form and
its associated documentation.

2. Subject to the terms and conditions of this License Agreement, PSF hereby
grants Licensee a nonexclusive, royalty-free, world-wide license to reproduce,
analyze, test, perform and/or display publicly, prepare derivative works,
distribute, and otherwise use Python alone or in any derivative version,
provided, however, that PSF's License Agreement and PSF's notice of copyright,
i.e., "Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023
Python Software Foundation;
All Rights Reserved" are retained in Python alone or in any derivative version
prepared by Licensee.

3. In the event Licensee prepares a derivative work that is based on
or incorporates Python or any part thereof, and wants to make
the derivative work available to others as provided herein, then
Licensee hereby agrees to include in any such work a brief summary of
the changes made to Python.

4. PSF is making Python available to Licensee on an "AS IS"
basis.  PSF MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PSF MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF MERCHANTABILITY OR FITNESS
FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF PYTHON WILL NOT
INFRINGE ANY THIRD PARTY RIGHTS.

5. PSF SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF PYTHON
FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS AS
A RESULT OF MODIFYING, DISTRIBUTING, OR OTHERWISE USING PYTHON,
OR ANY DERIVATIVE THEREOF, EVEN IF ADVISED OF THE POSSIBILITY THEREOF.

6. This License Agreement will automatically terminate upon a material
breach of its terms and conditions.

7. Nothing in this License Agreement shall be deemed to create any
relationship of agency, partnership, or joint venture between PSF and
Licensee.  This License Agreement does not grant permission to use PSF
trademarks or trade name in a trademark sense to endorse or promote
products or services of Licensee, or any third party.

8. By copying, installing or otherwise using Python, Licensee
agrees to be bound by the terms and conditions of this License
Agreement.


BEOPEN.COM LICENSE AGREEMENT FOR PYTHON 2.0
-------------------------------------------

BEOPEN PYTHON OPEN SOURCE LICENSE AGREEMENT VERSION 1

1. This LICENSE AGREEMENT is between BeOpen.com ("BeOpen"), having an
office at 160 Saratoga Avenue, Santa Clara, CA 95051, and the
Individual or Organization ("Licensee") accessing and otherwise using
this software in source or binary form and its associated
documentation ("the Software").

2. Subject to the terms and conditions of this BeOpen Python License
Agreement, BeOpen hereby grants Licensee a non-exclusive,
royalty-free, world-wide license to reproduce, analyze, test, perform
and/or display publicly, prepare derivative works, distribute, and
otherwise use the Software alone or in any derivative version,
provided, however, that the BeOpen Python License is retained in the
Software, alone or in any derivative version prepared by Licensee.

3. BeOpen is making the Software available to Licensee on an "AS IS"
basis.  BEOPEN MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, BEOPEN MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF MERCHANTABILITY OR FITNESS
FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE WILL NOT
INFRINGE ANY THIRD PARTY RIGHTS.

4. BEOPEN SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF THE
SOFTWARE FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS
AS A RESULT OF USING, MODIFYING OR DISTRIBUTING THE SOFTWARE, OR ANY
DERIVATIVE THEREOF, EVEN IF ADVISED OF THE POSSIBILITY THEREOF.

5. This License Agreement will automatically terminate upon a material
breach of its terms and conditions.

6. This License Agreement shall be governed by and interpreted in all
respects by the law of the State of California, excluding conflict of
law provisions.  Nothing in this License Agreement shall be deemed to
create any relationship of agency, partnership, or joint venture
between BeOpen and Licensee.  This License Agreement does not grant
permission to use BeOpen trademarks or trade names in a trademark
sense to endorse or promote products or services of Licensee, or any
third party.  As an exception, the "BeOpen Python" logos available at
http://www.pythonlabs.com/logos.html may be used according to the
permissions granted on that web page.

7. By copying, installing or otherwise using the software, Licensee
agrees to be bound by the terms and conditions of this License
Agreement.


CNRI LICENSE AGREEMENT FOR PYTHON 1.6.1
---------------------------------------

1. This LICENSE AGREEMENT is between the Corporation for National
Research Initiatives, having an office at 1895 Preston White Drive,
Reston, VA 20191 ("CNRI"), and the Individual or Organization
("Licensee") accessing and otherwise using Python 1.6.1 software in
source or binary form and its associated documentation.

2. Subject to the terms and conditions of this License Agreement, CNRI
hereby grants Licensee a nonexclusive, royalty-free, world-wide
license to reproduce, analyze, test, perform and/or display publicly,
prepare derivative works, distribute, and otherwise use Python 1.6.1
alone or in any derivative version, provided, however, that CNRI's
License Agreement and CNRI's notice of copyright, i.e., "Copyright (c)
1995-2001 Corporation for National Research Initiatives; All Rights
Reserved" are retained in Python 1.6.1 alone or in any derivative
version prepared by Licensee.  Alternately, in lieu of CNRI's License
Agreement, Licensee may substitute the following text (omitting the
quotes): "Python 1.6.1 is made available subject to the terms and
conditions in CNRI's License Agreement.  This Agreement together with
Python 1.6.1 may be located on the internet using the following
unique, persistent identifier (known as a handle): 1895.22/1013.  This
Agreement may also be obtained from a proxy server on the internet
using the following URL: http://hdl.handle.net/1895.22/1013".

3. In the event Licensee prepares a derivative work that is based on
or incorporates Python 1.6.1 or any part thereof, and wants to make
the derivative work available to others as provided herein, then
Licensee hereby agrees to include in any such work a brief summary of
the changes made to Python 1.6.1.

4. CNRI is making Python 1.6.1 available to Licensee on an "AS IS"
basis.  CNRI MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, CNRI MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF MERCHANTABILITY OR FITNESS
FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF PYTHON 1.6.1 WILL NOT
INFRINGE ANY THIRD PARTY RIGHTS.

5. CNRI SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF PYTHON
1.6.1 FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS AS
A RESULT OF MODIFYING, DISTRIBUTING, OR OTHERWISE USING PYTHON 1.6.1,
OR ANY DERIVATIVE THEREOF, EVEN IF ADVISED OF THE POSSIBILITY THEREOF.

6. This License Agreement will automatically terminate upon a material
breach of its terms and conditions.

7. This License Agreement shall be governed by the federal
intellectual property law of the United States, including without
limitation the federal copyright law, and, to the extent such
U.S. federal law does not apply, by the law of the Commonwealth of
Virginia, excluding Virginia's conflict of law provisions.
Notwithstanding the foregoing, with regard to derivative works based
on Python 1.6.1 that incorporate non-separable material that was
previously distributed under the GNU General Public License (GPL), the
law of the Commonwealth of Virginia shall govern this License
Agreement only as to issues arising under or with respect to
Paragraphs 4, 5, and 7 of this License Agreement.  Nothing in this
License Agreement shall be deemed to create any relationship of
agency, partnership, or joint venture between CNRI and Licensee.  This
License Agreement does not grant permission to use CNRI trademarks or
trade name in a trademark sense to endorse or promote products or
services of Licensee, or any third party.

8. By clicking on the "ACCEPT" button where indicated, or by copying,
installing or otherwise using Python 1.6.1, Licensee agrees to be
bound by the terms and conditions of this License Agreement.

        ACCEPT


CWI LICENSE AGREEMENT FOR PYTHON 0.9.0 THROUGH 1.2
--------------------------------------------------

Copyright (c) 1991 - 1995, Stichting Mathematisch Centrum Amsterdam,
The Netherlands.  All rights reserved.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of Stichting Mathematisch
Centrum or CWI not be used in advertising or publicity pertaining to
distribution of the software without specific, written prior
permission.

STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO
THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS, IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

ZERO-CLAUSE BSD LICENSE FOR CODE IN THE PYTHON DOCUMENTATION
----------------------------------------------------------------------

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
```

---

## enroot; version 3.4.1

<https://github.com/NVIDIA/enroot>

```text

    * Package enroot's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/enroot/enroot-3.4.1-1.el8.x86_64.rpm

This product bundles libbsd, which is available under a dual
"3-clause BSD" and "ISC" license.  For details, see deps/libbsd/.

This product bundles makeself, which is available under a
"GNU General Public License v2.0" license.  For details, see deps/makeself/.

This product bundles linux-headers, which is available under a
"GNU General Public License v2.0 WITH syscall exception" license.  For details,
see deps/linux-headers/.

This product bundles musl, which is available under a
"MIT" license.  For details, see deps/musl/.
* For enroot see also this required NOTICE:
    Copyright (c) 2018-2023, NVIDIA CORPORATION. All rights reserved.
```

---

## requests; version 2.32.5

<https://pypi.org/project/requests/>

```text

    * Package requests's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.
* For requests see also this required NOTICE:
    Requests
    Copyright 2019 Kenneth Reitz
```

---

## cookbook-line (grouped with 12 other entries sharing this license)

**Entries covered by the license text below:**

- **cookbook-line; version 4.5.21** — <https://supermarket.chef.io/cookbooks/line>
- **cookbook-yum-epel; version 5.0.8** — <https://supermarket.chef.io/cookbooks/yum-epel>
- **cookbook-yum; version 7.4.20** — <https://supermarket.chef.io/cookbooks/yum>
- **cookbook-openssh; version 2.11.14** — <https://supermarket.chef.io/cookbooks/openssh>
- **cookbook-nfs; version 5.1.5** — <https://supermarket.chef.io/cookbooks/nfs>
- **cookbook-iptables; version 8.0.0** — <https://supermarket.chef.io/cookbooks/iptables>
- **aws-cfn-bootstrap; version 2.0-38** — <https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html>
- **RubyGem - berkshelf; version 8.0.7** — <https://rubygems.org/gems/berkshelf/versions/8.0.7>
- **pyxis; version 0.20.0** — <https://github.com/NVIDIA/pyxis>
- **awscli; version 1.44.18** — <https://pypi.org/project/awscli/1.44.18/>
- **boto3; version 1.42.31** — <https://pypi.org/project/boto3/>
- **retrying; version 1.3.4** — <https://pypi.org/project/retrying/>
- **python-daemon; version 2.2.4** — <https://pypi.org/project/python-daemon/>

```text

    * Package python-daemon's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package retrying's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package boto3's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package awscli's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package pyxis's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/pyxis/v0.20.0.tar.gz

    * Package RubyGem - berkshelf's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/ruby/gems.tgz

    * Package aws-cfn-bootstrap's source code may be found at:
      https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-
py3-latest.tar.gz

    * Package cookbook-nfs's source code may be found at:
      https://github.com/sous-chefs/nfs/archive/refs/tags/5.1.5.tar.gz

    * Package cookbook-openssh's source code may be found at:
      https://github.com/sous-chefs/openssh/archive/refs/tags/2.11.15.tar.gz

    * Package cookbook-yum's source code may be found at:
      https://github.com/sous-chefs/yum/archive/refs/tags/7.4.20.tar.gz

    * Package cookbook-yum-epel's source code may be found at:
      https://github.com/sous-chefs/yum-epel/archive/refs/tags/5.0.8.tar.gz

    * Package cookbook-line's source code may be found at:
      https://github.com/sous-chefs/line/archive/refs/tags/4.5.21.tar.gz

Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.

"License" shall mean the terms and conditions for use, reproduction, and
distribution as defined by Sections 1 through 9 of this document.

"Licensor" shall mean the copyright owner or entity authorized by the copyright
owner that is granting the License.

"Legal Entity" shall mean the union of the acting entity and all other entities
that control, are controlled by, or are under common control with that entity.
For the purposes of this definition, "control" means (i) the power, direct or
indirect, to cause the direction or management of such entity, whether by
contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the
outstanding shares, or (iii) beneficial ownership of such entity.

"You" (or "Your") shall mean an individual or Legal Entity exercising
permissions granted by this License.

"Source" form shall mean the preferred form for making modifications, including
but not limited to software source code, documentation source, and configuration
files.

"Object" form shall mean any form resulting from mechanical transformation or
translation of a Source form, including but not limited to compiled object code,
generated documentation, and conversions to other media types.

"Work" shall mean the work of authorship, whether in Source or Object form, made
available under the License, as indicated by a copyright notice that is included
in or attached to the work (an example is provided in the Appendix below).

"Derivative Works" shall mean any work, whether in Source or Object form, that
is based on (or derived from) the Work and for which the editorial revisions,
annotations, elaborations, or other modifications represent, as a whole, an
original work of authorship. For the purposes of this License, Derivative Works
shall not include works that remain separable from, or merely link (or bind by
name) to the interfaces of, the Work and Derivative Works thereof.

"Contribution" shall mean any work of authorship, including the original version
of the Work and any modifications or additions to that Work or Derivative Works
thereof, that is intentionally submitted to Licensor for inclusion in the Work
by the copyright owner or by an individual or Legal Entity authorized to submit
on behalf of the copyright owner. For the purposes of this definition,
"submitted" means any form of electronic, verbal, or written communication sent
to the Licensor or its representatives, including but not limited to
communication on electronic mailing lists, source code control systems, and
issue tracking systems that are managed by, or on behalf of, the Licensor for
the purpose of discussing and improving the Work, but excluding communication
that is conspicuously marked or otherwise designated in writing by the copyright
owner as "Not a Contribution."

"Contributor" shall mean Licensor and any individual or Legal Entity on behalf
of whom a Contribution has been received by Licensor and subsequently
incorporated within the Work.

2. Grant of Copyright License. Subject to the terms and conditions of this
License, each Contributor hereby grants to You a perpetual, worldwide, non-
exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce,
prepare Derivative Works of, publicly display, publicly perform, sublicense, and
distribute the Work and such Derivative Works in Source or Object form.

3. Grant of Patent License. Subject to the terms and conditions of this License,
each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-
charge, royalty-free, irrevocable (except as stated in this section) patent
license to make, have made, use, offer to sell, sell, import, and otherwise
transfer the Work, where such license applies only to those patent claims
licensable by such Contributor that are necessarily infringed by their
Contribution(s) alone or by combination of their Contribution(s) with the Work
to which such Contribution(s) was submitted. If You institute patent litigation
against any entity (including a cross-claim or counterclaim in a lawsuit)
alleging that the Work or a Contribution incorporated within the Work
constitutes direct or contributory patent infringement, then any patent licenses
granted to You under this License for that Work shall terminate as of the date
such litigation is filed.

4. Redistribution. You may reproduce and distribute copies of the Work or
Derivative Works thereof in any medium, with or without modifications, and in
Source or Object form, provided that You meet the following conditions:

     (a) You must give any other recipients of the Work or Derivative Works a
copy of this License; and

     (b) You must cause any modified files to carry prominent notices stating
that You changed the files; and

     (c) You must retain, in the Source form of any Derivative Works that You
distribute, all copyright, patent, trademark, and attribution notices from the
Source form of the Work, excluding those notices that do not pertain to any part
of the Derivative Works; and

     (d) If the Work includes a "NOTICE" text file as part of its distribution,
then any Derivative Works that You distribute must include a readable copy of
the attribution notices contained within such NOTICE file, excluding those
notices that do not pertain to any part of the Derivative Works, in at least one
of the following places: within a NOTICE text file distributed as part of the
Derivative Works; within the Source form or documentation, if provided along
with the Derivative Works; or, within a display generated by the Derivative
Works, if and wherever such third-party notices normally appear. The contents of
the NOTICE file are for informational purposes only and do not modify the
License. You may add Your own attribution notices within Derivative Works that
You distribute, alongside or as an addendum to the NOTICE text from the Work,
provided that such additional attribution notices cannot be construed as
modifying the License.

     You may add Your own copyright statement to Your modifications and may
provide additional or different license terms and conditions for use,
reproduction, or distribution of Your modifications, or for any such Derivative
Works as a whole, provided Your use, reproduction, and distribution of the Work
otherwise complies with the conditions stated in this License.

5. Submission of Contributions. Unless You explicitly state otherwise, any
Contribution intentionally submitted for inclusion in the Work by You to the
Licensor shall be under the terms and conditions of this License, without any
additional terms or conditions. Notwithstanding the above, nothing herein shall
supersede or modify the terms of any separate license agreement you may have
executed with Licensor regarding such Contributions.

6. Trademarks. This License does not grant permission to use the trade names,
trademarks, service marks, or product names of the Licensor, except as required
for reasonable and customary use in describing the origin of the Work and
reproducing the content of the NOTICE file.

7. Disclaimer of Warranty. Unless required by applicable law or agreed to in
writing, Licensor provides the Work (and each Contributor provides its
Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied, including, without limitation, any warranties
or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
PARTICULAR PURPOSE. You are solely responsible for determining the
appropriateness of using or redistributing the Work and assume any risks
associated with Your exercise of permissions under this License.

8. Limitation of Liability. In no event and under no legal theory, whether in
tort (including negligence), contract, or otherwise, unless required by
applicable law (such as deliberate and grossly negligent acts) or agreed to in
writing, shall any Contributor be liable to You for damages, including any
direct, indirect, special, incidental, or consequential damages of any character
arising as a result of this License or out of the use or inability to use the
Work (including but not limited to damages for loss of goodwill, work stoppage,
computer failure or malfunction, or any and all other commercial damages or
losses), even if such Contributor has been advised of the possibility of such
damages.

9. Accepting Warranty or Additional Liability. While redistributing the Work or
Derivative Works thereof, You may choose to offer, and charge a fee for,
acceptance of support, warranty, indemnity, or other liability obligations
and/or rights consistent with this License. However, in accepting such
obligations, You may act only on Your own behalf and on Your sole
responsibility, not on behalf of any other Contributor, and only if You agree to
indemnify, defend, and hold each Contributor harmless for any liability incurred
by, or claims asserted against, such Contributor by reason of your accepting any
such warranty or additional liability.

END OF TERMS AND CONDITIONS

APPENDIX: How to apply the Apache License to your work.

To apply the Apache License to your work, attach the following boilerplate
notice, with the fields enclosed by brackets "[]" replaced with your own
identifying information. (Don't include the brackets!)  The text should be
enclosed in the appropriate comment syntax for the file format. We also
recommend that a file or class name and description of purpose be included on
the same "printed page" as the copyright notice for easier identification within
third-party archives.

Copyright [yyyy] [name of copyright owner]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

* For cookbook-line see also this required NOTICE:
    None
* For cookbook-yum-epel see also this required NOTICE:
    None
* For cookbook-yum see also this required NOTICE:
    None
* For cookbook-openssh see also this required NOTICE:
    None
* For cookbook-nfs see also this required NOTICE:
    None
* For aws-cfn-bootstrap see also this required NOTICE:
    aws-cfn-bootstrap
    Copyright 2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
    aws-cfn-bootstrap is licensed under the Apache License, version 2.0,
included
    in the file LICENSE.txt

    aws-cfn-bootstrap includes a vendorized copy of the requests python library
to ease installation.

    Requests License
    ================

    Copyright 2013 Kenneth Reitz

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

           http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.


    The requests library also includes some vendorized python libraries to ease
installation.

    Urllib3 License
    ===============

    This is the MIT license: http://www.opensource.org/licenses/mit-license.php

    Copyright 2008-2011 Andrey Petrov and contributors (see CONTRIBUTORS.txt),
    Modifications copyright 2012 Kenneth Reitz.

    Permission is hereby granted, free of charge, to any person obtaining a copy
of this
    software and associated documentation files (the "Software"), to deal in the
Software
    without restriction, including without limitation the rights to use, copy,
modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons
    to whom the Software is furnished to do so, subject to the following
conditions:

    The above copyright notice and this permission notice shall be included in
all copies or
    substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR
A PARTICULAR
    PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE
    FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR
    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER
    DEALINGS IN THE SOFTWARE.

    Chardet License
    ================

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301  USA

    Chevron License
    ===============
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE
    SOFTWARE.

    Bundle of CA Root Certificates
    ==============================

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301
* For RubyGem - berkshelf see also this required NOTICE:
    -
* For pyxis see also this required NOTICE:
    Copyright 2019-2020 NVIDIA CORPORATION

* For awscli see also this required NOTICE:
    Copyright 2012-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
* For boto3 see also this required NOTICE:
    boto3
    Copyright 2013-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
* For retrying see also this required NOTICE:
    Copyright 2013 Ray Holder
* For python-daemon see also this required NOTICE:
    This work, ‘python-daemon’, is free software: you may copy, modify,
    and/or distribute this work under certain conditions; see the relevant
    files for specific grant of license. No warranty expressed or implied.

    * Parts of this work are licensed to you under the terms of the GNU
      General Public License as published by the Free Software Foundation;
      version 3 of that license or any later version.
      See the file ‘LICENSE.GPL-3’ for details.

    * Parts of this work are licensed to you under the terms of the Apache
      License, version 2.0 as published by the Apache Software Foundation.
      See the file ‘LICENSE.ASF-2’ for details.

    ?
    ..
        This document is written using `reStructuredText`_ markup, and can
        be rendered with `Docutils`_ to other formats.

        ..  _Docutils: http://docutils.sourceforge.net/
        ..  _reStructuredText: http://docutils.sourceforge.net/rst.html

    ..
        This is free software: you may copy, modify, and/or distribute this work
        under the terms of the Apache License version 2.0 as published by the
        Apache Software Foundation.
        No warranty expressed or implied. See the file ‘LICENSE.ASF-2’ for
details.

    ..
        Local variables:
        coding: utf-8
        mode: rst
        mode: text
        End:
        vim: fileencoding=utf-8 filetype=rst :
```

---

## supervisor; version 4.3.0

<https://pypi.org/project/supervisor/>

```text
Supervisor is Copyright (c) 2006-2015 Agendaless Consulting and Contributors.
(http://www.agendaless.com), All Rights Reserved

  This software is subject to the provisions of the license at
  http://www.repoze.org/LICENSE.txt . A copy of this license should
  accompany this distribution.  THIS SOFTWARE IS PROVIDED "AS IS" AND
  ANY AND ALL EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED, INCLUDING,
  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF TITLE,
  MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS FOR A PARTICULAR
  PURPOSE.

TrackRefs code Copyright (c) 2007 Zope Corporation and Contributors

  This software is subject to the provisions of the Zope Public License,
  Version 2.1 (ZPL). A copy of the ZPL should accompany this distribution.
  THIS SOFTWARE IS PROVIDED "AS IS" AND ANY AND ALL EXPRESS OR IMPLIED
  WARRANTIES ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF TITLE, MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS
  FOR A PARTICULAR PURPOSE.

medusa was (is?) Copyright (c) Sam Rushing.

http_client.py code Copyright (c) by Daniel Krech, http://eikeon.com/.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    * Package supervisor's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Supervisor is licensed under the following license:

  A copyright notice accompanies this license document that identifies
  the copyright holders.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1.  Redistributions in source code must retain the accompanying
      copyright notice, this list of conditions, and the following
      disclaimer.

  2.  Redistributions in binary form must reproduce the accompanying
      copyright notice, this list of conditions, and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

  3.  Names of the copyright holders must not be used to endorse or
      promote products derived from this software without prior
      written permission from the copyright holders.

  4.  If any files are modified, you must cause the modified files to
      carry prominent notices stating that you changed the files and
      the date of any change.

  Disclaimer

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND
    ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    HOLDERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
    TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

http_client.py code is based on code by Daniel Krech, which was
released under this license:

  LICENSE AGREEMENT FOR RDFLIB 0.9.0 THROUGH 2.3.1
  ------------------------------------------------
  Copyright (c) 2002-2005, Daniel Krech, http://eikeon.com/
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

    * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the following
  disclaimer in the documentation and/or other materials provided
  with the distribution.

    * Neither the name of Daniel Krech nor the names of its
  contributors may be used to endorse or promote products derived
  from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Medusa, the asynchronous communications framework upon which
supervisor's server and client code is based, was created by Sam
Rushing:

  Medusa was once distributed under a 'free for non-commercial use'
  license, but in May of 2000 Sam Rushing changed the license to be
  identical to the standard Python license at the time.  The standard
  Python license has always applied to the core components of Medusa,
  this change just frees up the rest of the system, including the http
  server, ftp server, utilities, etc.  Medusa is therefore under the
  following license:

  ==============================
  Permission to use, copy, modify, and distribute this software and
  its documentation for any purpose and without fee is hereby granted,
  provided that the above copyright notice appear in all copies and
  that both that copyright notice and this permission notice appear in
  supporting documentation, and that the name of Sam Rushing not be
  used in advertising or publicity pertaining to distribution of the
  software without specific, written prior permission.

  SAM RUSHING DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
  INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN
  NO EVENT SHALL SAM RUSHING BE LIABLE FOR ANY SPECIAL, INDIRECT OR
  CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
  OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
  WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ==============================

Some software in this distribution is released under the Zope Public
License (as marked in its file header):

  Zope Public License (ZPL) Version 2.1
  -------------------------------------

  A copyright notice accompanies this license document that
  identifies the copyright holders.

  This license has been certified as open source. It has also
  been designated as GPL compatible by the Free Software
  Foundation (FSF).

  Redistribution and use in source and binary forms, with or
  without modification, are permitted provided that the
  following conditions are met:

  1. Redistributions in source code must retain the
     accompanying copyright notice, this list of conditions,
     and the following disclaimer.

  2. Redistributions in binary form must reproduce the accompanying
     copyright notice, this list of conditions, and the
     following disclaimer in the documentation and/or other
     materials provided with the distribution.

  3. Names of the copyright holders must not be used to
     endorse or promote products derived from this software
     without prior written permission from the copyright
     holders.

  4. The right to distribute this software or to use it for
     any purpose does not give you the right to use
     Servicemarks (sm) or Trademarks (tm) of the copyright
     holders. Use of them is covered by separate agreement
     with the copyright holders.

  5. If any files are modified, you must cause the modified
     files to carry prominent notices stating that you changed
     the files and the date of any change.

  Disclaimer

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS''
    AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT
    NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN
    NO EVENT SHALL THE COPYRIGHT HOLDERS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
    DAMAGE.
```

---

## docutils; version 0.22.4

<https://pypi.org/project/docutils/>

```text
Copyright: David Goodger

    * Package docutils's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Copyright (c) <year> <owner> All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

## jinja2; version 3.1.6

<https://pypi.org/project/Jinja2/>

```text
Copyright 2007 Pallets
```

## click; version 8.1.7

<https://pypi.org/project/click/>

```text
Copyright 2014 Pallets

    * Package click's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package jinja2's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

3.  Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

## Arm Performance Libraries; version 24.10

<https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-performance-libraries>

```text
================================================================================
This file lists the package level copyright and license information for third
party software included in this release of 'Arm Performance Libraries'. Refer
to the End User License Agreement that accompanies this release of 'Arm
Performance Libraries' for terms and conditions relating to your use of such
third party software.

The information is grouped into two sections. The first section lists out
details of third party software projects, including names of the applicable
licenses as per the SPDX format (http://spdx.org/licenses). The second section
includes the full license text of all applicable licenses referenced in the
first section.
================================================================================

SECTION 1: THIRD PARTY SOFTWARE PROJECTS
================================================================================

Name:         SLEEF - a99491a
Summary:      SLEEF(SIMD Library for Evaluating Elementary Functions) Vectorized
              Math Library.
Home-page:    https://sleef.org/
License(s):   Boost Software License 1.0 (BSL-1.0). See later section for a copy
              of license text.
Copyright(s): Refer to Sources:
              https://github.com/shibatch/sleef/tree/a99491a
---------------------------------------------------------------------

Name:         FFTW header v3.3.10
Summary:      FFTW (Fast Fourier Transform in the West) is typically faster than
              other publically-available FFT implementations. This is the header
              file for FFTW.
Home-page:    https://www.fftw.org/
License(s):   BSD 2-clause "Simplified" License (BSD-2-Clause). See later
              section for a copy of license text.
Copyright(s): Refer to Sources:
              https://github.com/FFTW/fftw3/blob/master/api/fftw3.h
---------------------------------------------------------------------

Name:         Netlib LAPACK v3.12.0
Summary:      LAPACK (Linear Algebra PACKage) is written in Fortran 90 and
              provides routines for solving systems of simultaneous linear
              equations, least-squares solutions of linear systems of equations,
              eigenvalue problems, and singular value problems.
Home-page:    http://www.netlib.org/lapack/
License(s):   BSD 3-Clause "New" or "Revised" License (BSD-3-Clause). See later
              section for a copy of license text.
Copyright(s): Refer to Sources:
              http://www.netlib.org/lapack/#_lapack_version_3_12_0
---------------------------------------------------------------------

Name:         JSON for Modern C++ v3.1.2
Summary:      A library for manipulating JSON data in C++.
Home-page:    https://github.com/nlohmann/json
License(s):   MIT License (MIT). See later section for a copy of license text.
Copyright(s): Refer to Sources:
              https://github.com/nlohmann/json/tree/v3.1.2
---------------------------------------------------------------------

Name:         optimized-routines (Arm) - e00681d
Summary:      Optimized implementations of various library functions for Arm
              architecture processors.
Home-page:    https://github.com/ARM-software/optimized-routines
License(s):   MIT License (MIT) OR Apache-2.0 WITH LLVM-exception. See later
              section for a copy of license text.
Copyright(s): Refer to Sources:
              https://github.com/ARM-software/optimized-routines/tree/e00681d
---------------------------------------------------------------------

Name:         Cortex-A String Routines - 499d1a6
Summary:      Optimised string routines including memcpy(), memset(),strcpy(),
              strlen() for the ARM Cortex-A series of cores.
Home-page:    https://git.linaro.org/toolchain/cortex-strings.git/about/
License(s):   BSD 3-Clause "New" or "Revised" License (BSD-3-Clause). See later
              section for a copy of license text.
Copyright(s): Refer to Sources:
https://git.linaro.org/toolchain/cortex-strings.git/tree/src/aarch64?id=499d1a6
---------------------------------------------------------------------

Name:         libpgmath - 8e65ce5
Summary:      Run time library for Flang (Fortran compiler targeting LLVM).
Home-page:    https://github.com/flang-compiler/flang/tree/master/runtime
License(s):   Apache License 2.0 (Apache-2.0). See later section for a copy of
              license text.
Copyright(s): Refer to Sources:
          https://github.com/flang-compiler/flang/tree/8e65ce5/runtime/libpgmath
---------------------------------------------------------------------

Name:         gcc v14.2.0
Home-page:    https://gcc.gnu.org/gcc-14/
Summary:      Fortran and C++ standard runtime libraries.
License(s):   See later section for a copy of GCC RUNTIME LIBRARY EXCEPTION
              licence.
Sources:      Sources for this are made available as a separate package
https://developer.arm.com/Tools%20and%20Software/Arm%20Compiler%20for%20Linux#Do
wnloads
----------------------------------------------------------------------

Name:         Mersenne Twister - 2002/1/26
Summary:      Mersenne twister initialization.
Home-page:
http://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/MT2002/emt19937ar.html
License(s):   BSD 3-Clause. See later section for a copy of license text.
Copyright(s): Refer to Sources:
http://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/MT2002/CODES/mt19937ar.c
----------------------------------------------------------------------

Name:         SFMT - 2017/2/22
Summary:      SFMT initialization.
Home-page:    http://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/SFMT/index.html
License(s):   BSD 3-Clause. See later section for a copy of license text.
Copyright(s): Refer to Sources:
              http://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/SFMT/SFMT-
src-1.5.1.tar.gz
----------------------------------------------------------------------

Name:         oneMKL RNG API - 2024-1
Summary:      The RNG component of Intel's Vector Statistics Library.
Home-page:    https://www.intel.com/content/www/us/en/docs/onemkl/developer-
reference-c
License(s):   CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/). See
              later section for a copy of license text.
Copyright(s): 2024 Intel Corporation

================================================================================

SECTION 2: APPLICABLE LICENSES
================================================================================
1) License Text (Apache 2.0) for 'libpgmath':

Copyright (c) 2018, NVIDIA CORPORATION.  All rights reserved. (libpgmath)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
================================================================================

2) License Text (BSL-1.0) for 'SLEEF':
Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
================================================================================

3) License Text for (MIT) 'optimized-routines' and 'JSON for Modern C++':
Copyright (c) 1999-2019, Arm Limited. (for optimized-routines)
Copyright (c) 2013-2018 Niels Lohmann. (for JSON for Modern C++ )

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
================================================================================

4) License Text (BSD-2-Clause) for 'FFTW header':
Copyright (c) 2003, 2007-14 Matteo Frigo
Copyright (c) 2003, 2007-14 Massachusetts Institute of Technology

The following statement of license applies *only* to this header file,
and *not* to the other files distributed with FFTW or derived therefrom:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
================================================================================

5) License Text (BSD-3-Clause) for 'Cortex-A String Routines':
  Copyright (c) 2013, 2018 Linaro Limited
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
       * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in the
         documentation and/or other materials provided with the distribution.
       * Neither the name of the Linaro nor the
         names of its contributors may be used to endorse or promote products
         derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
================================================================================

6) License Text (BSD-3-Clause) for 'Netlib LAPACK':
Copyright (c) 1992-2017 The University of Tennessee and The University
                        of Tennessee Research Foundation.  All rights
                        reserved.
Copyright (c) 2000-2017 The University of California Berkeley. All
                        rights reserved.
Copyright (c) 2006-2017 The University of Colorado Denver.  All rights
                        reserved.

$COPYRIGHT$

Additional copyrights may follow

$HEADER$

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer listed
  in this license in the documentation and/or other materials
  provided with the distribution.

- Neither the name of the copyright holders nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

The copyright holders provide no reassurances that the source code
provided does not infringe any patent, copyright, or any other
intellectual property rights of third parties.  The copyright holders
disclaim any liability to any recipient for claims brought against
recipient by any third party for infringement of that parties
intellectual property rights.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------
Netlib LAPACKE ( C Interface to LAPACK) included in the LAPACK package
(collaboration LAPACK and INTEL Math Kernel Library Team)
                                LAPACKE Licenses:
  Copyright (c) 2012, Intel Corp.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Intel Corporation nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
  THE POSSIBILITY OF SUCH DAMAGE.
================================================================================

7) License Text (GPL-3.0-only WITH GCC-exception-3.1) for 'libstdc++' and
   also for 'libgfortran':

                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.
==================================================

GCC RUNTIME LIBRARY EXCEPTION

Version 3.1, 31 March 2009

Copyright (C) 2009 Free Software Foundation, Inc. <http://fsf.org/>

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

This GCC Runtime Library Exception ("Exception") is an additional
permission under section 7 of the GNU General Public License, version
3 ("GPLv3"). It applies to a given file (the "Runtime Library") that
bears a notice placed by the copyright holder of the file stating that
the file is governed by GPLv3 along with this Exception.

When you use GCC to compile a program, GCC may combine portions of
certain GCC header files and runtime libraries with the compiled
program. The purpose of this Exception is to allow compilation of
non-GPL (including proprietary) programs to use, in this way, the
header files and runtime libraries covered by this Exception.

0. Definitions.

A file is an "Independent Module" if it either requires the Runtime
Library for execution after a Compilation Process, or makes use of an
interface provided by the Runtime Library, but is not otherwise based
on the Runtime Library.

"GCC" means a version of the GNU Compiler Collection, with or without
modifications, governed by version 3 (or a specified later version) of
the GNU General Public License (GPL) with the option of using any
subsequent versions published by the FSF.

"GPL-compatible Software" is software whose conditions of propagation,
modification and use would permit combination with GCC in accord with
the license of GCC.

"Target Code" refers to output from any compiler for a real or virtual
target processor architecture, in executable form or suitable for
input to an assembler, loader, linker and/or execution
phase. Notwithstanding that, Target Code does not include data in any
format that is used as a compiler intermediate representation, or used
for producing a compiler intermediate representation.

The "Compilation Process" transforms code entirely represented in
non-intermediate languages designed for human-written code, and/or in
Java Virtual Machine byte code, into Target Code. Thus, for example,
use of source code generators and preprocessors need not be considered
part of the Compilation Process, since the Compilation Process can be
understood as starting with the output of the generators or
preprocessors.

A Compilation Process is "Eligible" if it is done using GCC, alone or
with other GPL-compatible software, or if it is done without using any
work based on GCC. For example, using non-GPL-compatible Software to
optimize any GCC intermediate representations would not qualify as an
Eligible Compilation Process.

1. Grant of Additional Permission.

You have permission to propagate a work of Target Code formed by
combining the Runtime Library with Independent Modules, even if such
propagation would otherwise violate the terms of GPLv3, provided that
all Target Code was generated by Eligible Compilation Processes. You
may then convey such a combination under terms of your choice,
consistent with the licensing of the Independent Modules.

2. No Weakening of GCC Copyleft.

The availability of this Exception does not imply any general
presumption that third-party software is unaffected by the copyleft
requirements of the license of GCC.
================================================================================

8) License Text (BSD-3-Clause) for 'Mersenne Twister':
   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER
OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
================================================================================

9) License Text (BSD-3-Clause) for 'SFMT':
Copyright (c) 2006,2007 Mutsuo Saito, Makoto Matsumoto and Hiroshima
University.
Copyright (c) 2012 Mutsuo Saito, Makoto Matsumoto, Hiroshima University
and The University of Tokyo.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the names of Hiroshima University, The University of
      Tokyo nor the names of its contributors may be used to endorse
      or promote products derived from this software without specific
      prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
================================================================================

10) CC-BY-4.0 for 'oneMKL RNG API':

Attribution 4.0 International

=======================================================================

Creative Commons Corporation ("Creative Commons") is not a law firm and
does not provide legal services or legal advice. Distribution of
Creative Commons public licenses does not create a lawyer-client or
other relationship. Creative Commons makes its licenses and related
information available on an "as-is" basis. Creative Commons gives no
warranties regarding its licenses, any material licensed under their
terms and conditions, or any related information. Creative Commons
disclaims all liability for damages resulting from their use to the
fullest extent possible.

Using Creative Commons Public Licenses

Creative Commons public licenses provide a standard set of terms and
conditions that creators and other rights holders may use to share
original works of authorship and other material subject to copyright
and certain other rights specified in the public license below. The
following considerations are for informational purposes only, are not
exhaustive, and do not form part of our licenses.

     Considerations for licensors: Our public licenses are
     intended for use by those authorized to give the public
     permission to use material in ways otherwise restricted by
     copyright and certain other rights. Our licenses are
     irrevocable. Licensors should read and understand the terms
     and conditions of the license they choose before applying it.
     Licensors should also secure all rights necessary before
     applying our licenses so that the public can reuse the
     material as expected. Licensors should clearly mark any
     material not subject to the license. This includes other CC-
     licensed material, or material used under an exception or
     limitation to copyright. More considerations for licensors:
    wiki.creativecommons.org/Considerations_for_licensors

     Considerations for the public: By using one of our public
     licenses, a licensor grants the public permission to use the
     licensed material under specified terms and conditions. If
     the licensor's permission is not necessary for any reason--for
     example, because of any applicable exception or limitation to
     copyright--then that use is not regulated by the license. Our
     licenses grant only permissions under copyright and certain
     other rights that a licensor has authority to grant. Use of
     the licensed material may still be restricted for other
     reasons, including because others have copyright or other
     rights in the material. A licensor may make special requests,
     such as asking that all changes be marked or described.
     Although not required by our licenses, you are encouraged to
     respect those requests where reasonable. More considerations
     for the public:
    wiki.creativecommons.org/Considerations_for_licensees

=======================================================================

Creative Commons Attribution 4.0 International Public License

By exercising the Licensed Rights (defined below), You accept and agree
to be bound by the terms and conditions of this Creative Commons
Attribution 4.0 International Public License ("Public License"). To the
extent this Public License may be interpreted as a contract, You are
granted the Licensed Rights in consideration of Your acceptance of
these terms and conditions, and the Licensor grants You such rights in
consideration of benefits the Licensor receives from making the
Licensed Material available under these terms and conditions.


Section 1 -- Definitions.

  a. Adapted Material means material subject to Copyright and Similar
     Rights that is derived from or based upon the Licensed Material
     and in which the Licensed Material is translated, altered,
     arranged, transformed, or otherwise modified in a manner requiring
     permission under the Copyright and Similar Rights held by the
     Licensor. For purposes of this Public License, where the Licensed
     Material is a musical work, performance, or sound recording,
     Adapted Material is always produced where the Licensed Material is
     synched in timed relation with a moving image.

  b. Adapter's License means the license You apply to Your Copyright
     and Similar Rights in Your contributions to Adapted Material in
     accordance with the terms and conditions of this Public License.

  c. Copyright and Similar Rights means copyright and/or similar rights
     closely related to copyright including, without limitation,
     performance, broadcast, sound recording, and Sui Generis Database
     Rights, without regard to how the rights are labeled or
     categorized. For purposes of this Public License, the rights
     specified in Section 2(b)(1)-(2) are not Copyright and Similar
     Rights.

  d. Effective Technological Measures means those measures that, in the
     absence of proper authority, may not be circumvented under laws
     fulfilling obligations under Article 11 of the WIPO Copyright
     Treaty adopted on December 20, 1996, and/or similar international
     agreements.

  e. Exceptions and Limitations means fair use, fair dealing, and/or
     any other exception or limitation to Copyright and Similar Rights
     that applies to Your use of the Licensed Material.

  f. Licensed Material means the artistic or literary work, database,
     or other material to which the Licensor applied this Public
     License.

  g. Licensed Rights means the rights granted to You subject to the
     terms and conditions of this Public License, which are limited to
     all Copyright and Similar Rights that apply to Your use of the
     Licensed Material and that the Licensor has authority to license.

  h. Licensor means the individual(s) or entity(ies) granting rights
     under this Public License.

  i. Share means to provide material to the public by any means or
     process that requires permission under the Licensed Rights, such
     as reproduction, public display, public performance, distribution,
     dissemination, communication, or importation, and to make material
     available to the public including in ways that members of the
     public may access the material from a place and at a time
     individually chosen by them.

  j. Sui Generis Database Rights means rights other than copyright
     resulting from Directive 96/9/EC of the European Parliament and of
     the Council of 11 March 1996 on the legal protection of databases,
     as amended and/or succeeded, as well as other essentially
     equivalent rights anywhere in the world.

  k. You means the individual or entity exercising the Licensed Rights
     under this Public License. Your has a corresponding meaning.


Section 2 -- Scope.

  a. License grant.

       1. Subject to the terms and conditions of this Public License,
          the Licensor hereby grants You a worldwide, royalty-free,
          non-sublicensable, non-exclusive, irrevocable license to
          exercise the Licensed Rights in the Licensed Material to:

            a. reproduce and Share the Licensed Material, in whole or
               in part; and

            b. produce, reproduce, and Share Adapted Material.

       2. Exceptions and Limitations. For the avoidance of doubt, where
          Exceptions and Limitations apply to Your use, this Public
          License does not apply, and You do not need to comply with
          its terms and conditions.

       3. Term. The term of this Public License is specified in Section
          6(a).

       4. Media and formats; technical modifications allowed. The
          Licensor authorizes You to exercise the Licensed Rights in
          all media and formats whether now known or hereafter created,
          and to make technical modifications necessary to do so. The
          Licensor waives and/or agrees not to assert any right or
          authority to forbid You from making technical modifications
          necessary to exercise the Licensed Rights, including
          technical modifications necessary to circumvent Effective
          Technological Measures. For purposes of this Public License,
          simply making modifications authorized by this Section 2(a)
          (4) never produces Adapted Material.

       5. Downstream recipients.

            a. Offer from the Licensor -- Licensed Material. Every
               recipient of the Licensed Material automatically
               receives an offer from the Licensor to exercise the
               Licensed Rights under the terms and conditions of this
               Public License.

            b. No downstream restrictions. You may not offer or impose
               any additional or different terms or conditions on, or
               apply any Effective Technological Measures to, the
               Licensed Material if doing so restricts exercise of the
               Licensed Rights by any recipient of the Licensed
               Material.

       6. No endorsement. Nothing in this Public License constitutes or
          may be construed as permission to assert or imply that You
          are, or that Your use of the Licensed Material is, connected
          with, or sponsored, endorsed, or granted official status by,
          the Licensor or others designated to receive attribution as
          provided in Section 3(a)(1)(A)(i).

  b. Other rights.

       1. Moral rights, such as the right of integrity, are not
          licensed under this Public License, nor are publicity,
          privacy, and/or other similar personality rights; however, to
          the extent possible, the Licensor waives and/or agrees not to
          assert any such rights held by the Licensor to the limited
          extent necessary to allow You to exercise the Licensed
          Rights, but not otherwise.

       2. Patent and trademark rights are not licensed under this
          Public License.

       3. To the extent possible, the Licensor waives any right to
          collect royalties from You for the exercise of the Licensed
          Rights, whether directly or through a collecting society
          under any voluntary or waivable statutory or compulsory
          licensing scheme. In all other cases the Licensor expressly
          reserves any right to collect such royalties.


Section 3 -- License Conditions.

Your exercise of the Licensed Rights is expressly made subject to the
following conditions.

  a. Attribution.

       1. If You Share the Licensed Material (including in modified
          form), You must:

            a. retain the following if it is supplied by the Licensor
               with the Licensed Material:

                 i. identification of the creator(s) of the Licensed
                    Material and any others designated to receive
                    attribution, in any reasonable manner requested by
                    the Licensor (including by pseudonym if
                    designated);

                ii. a copyright notice;

               iii. a notice that refers to this Public License;

                iv. a notice that refers to the disclaimer of
                    warranties;

                 v. a URI or hyperlink to the Licensed Material to the
                    extent reasonably practicable;

            b. indicate if You modified the Licensed Material and
               retain an indication of any previous modifications; and

            c. indicate the Licensed Material is licensed under this
               Public License, and include the text of, or the URI or
               hyperlink to, this Public License.

       2. You may satisfy the conditions in Section 3(a)(1) in any
          reasonable manner based on the medium, means, and context in
          which You Share the Licensed Material. For example, it may be
          reasonable to satisfy the conditions by providing a URI or
          hyperlink to a resource that includes the required
          information.

       3. If requested by the Licensor, You must remove any of the
          information required by Section 3(a)(1)(A) to the extent
          reasonably practicable.

       4. If You Share Adapted Material You produce, the Adapter's
          License You apply must not prevent recipients of the Adapted
          Material from complying with this Public License.


Section 4 -- Sui Generis Database Rights.

Where the Licensed Rights include Sui Generis Database Rights that
apply to Your use of the Licensed Material:

  a. for the avoidance of doubt, Section 2(a)(1) grants You the right
     to extract, reuse, reproduce, and Share all or a substantial
     portion of the contents of the database;

  b. if You include all or a substantial portion of the database
     contents in a database in which You have Sui Generis Database
     Rights, then the database in which You have Sui Generis Database
     Rights (but not its individual contents) is Adapted Material; and

  c. You must comply with the conditions in Section 3(a) if You Share
     all or a substantial portion of the contents of the database.

For the avoidance of doubt, this Section 4 supplements and does not
replace Your obligations under this Public License where the Licensed
Rights include other Copyright and Similar Rights.


Section 5 -- Disclaimer of Warranties and Limitation of Liability.

  a. UNLESS OTHERWISE SEPARATELY UNDERTAKEN BY THE LICENSOR, TO THE
     EXTENT POSSIBLE, THE LICENSOR OFFERS THE LICENSED MATERIAL AS-IS
     AND AS-AVAILABLE, AND MAKES NO REPRESENTATIONS OR WARRANTIES OF
     ANY KIND CONCERNING THE LICENSED MATERIAL, WHETHER EXPRESS,
     IMPLIED, STATUTORY, OR OTHER. THIS INCLUDES, WITHOUT LIMITATION,
     WARRANTIES OF TITLE, MERCHANTABILITY, FITNESS FOR A PARTICULAR
     PURPOSE, NON-INFRINGEMENT, ABSENCE OF LATENT OR OTHER DEFECTS,
     ACCURACY, OR THE PRESENCE OR ABSENCE OF ERRORS, WHETHER OR NOT
     KNOWN OR DISCOVERABLE. WHERE DISCLAIMERS OF WARRANTIES ARE NOT
     ALLOWED IN FULL OR IN PART, THIS DISCLAIMER MAY NOT APPLY TO YOU.

  b. TO THE EXTENT POSSIBLE, IN NO EVENT WILL THE LICENSOR BE LIABLE
     TO YOU ON ANY LEGAL THEORY (INCLUDING, WITHOUT LIMITATION,
     NEGLIGENCE) OR OTHERWISE FOR ANY DIRECT, SPECIAL, INDIRECT,
     INCIDENTAL, CONSEQUENTIAL, PUNITIVE, EXEMPLARY, OR OTHER LOSSES,
     COSTS, EXPENSES, OR DAMAGES ARISING OUT OF THIS PUBLIC LICENSE OR
     USE OF THE LICENSED MATERIAL, EVEN IF THE LICENSOR HAS BEEN
     ADVISED OF THE POSSIBILITY OF SUCH LOSSES, COSTS, EXPENSES, OR
     DAMAGES. WHERE A LIMITATION OF LIABILITY IS NOT ALLOWED IN FULL OR
     IN PART, THIS LIMITATION MAY NOT APPLY TO YOU.

  c. The disclaimer of warranties and limitation of liability provided
     above shall be interpreted in a manner that, to the extent
     possible, most closely approximates an absolute disclaimer and
     waiver of all liability.


Section 6 -- Term and Termination.

  a. This Public License applies for the term of the Copyright and
     Similar Rights licensed here. However, if You fail to comply with
     this Public License, then Your rights under this Public License
     terminate automatically.

  b. Where Your right to use the Licensed Material has terminated under
     Section 6(a), it reinstates:

       1. automatically as of the date the violation is cured, provided
          it is cured within 30 days of Your discovery of the
          violation; or

       2. upon express reinstatement by the Licensor.

     For the avoidance of doubt, this Section 6(b) does not affect any
     right the Licensor may have to seek remedies for Your violations
     of this Public License.

  c. For the avoidance of doubt, the Licensor may also offer the
     Licensed Material under separate terms or conditions or stop
     distributing the Licensed Material at any time; however, doing so
     will not terminate this Public License.

  d. Sections 1, 5, 6, 7, and 8 survive termination of this Public
     License.


Section 7 -- Other Terms and Conditions.

  a. The Licensor shall not be bound by any additional or different
     terms or conditions communicated by You unless expressly agreed.

  b. Any arrangements, understandings, or agreements regarding the
     Licensed Material not stated herein are separate from and
     independent of the terms and conditions of this Public License.


Section 8 -- Interpretation.

  a. For the avoidance of doubt, this Public License does not, and
     shall not be interpreted to, reduce, limit, restrict, or impose
     conditions on any use of the Licensed Material that could lawfully
     be made without permission under this Public License.

  b. To the extent possible, if any provision of this Public License is
     deemed unenforceable, it shall be automatically reformed to the
     minimum extent necessary to make it enforceable. If the provision
     cannot be reformed, it shall be severed from this Public License
     without affecting the enforceability of the remaining terms and
     conditions.

  c. No term or condition of this Public License will be waived and no
     failure to comply consented to unless expressly agreed to by the
     Licensor.

  d. Nothing in this Public License constitutes or may be interpreted
     as a limitation upon, or waiver of, any privileges and immunities
     that apply to the Licensor or You, including from the legal
     processes of any jurisdiction or authority.


=======================================================================

Creative Commons is not a party to its public
licenses. Notwithstanding, Creative Commons may elect to apply one of
its public licenses to material it publishes and in those instances
will be considered the “Licensor.” The text of the Creative Commons
public licenses is dedicated to the public domain under the CC0 Public
Domain Dedication. Except for the limited purpose of indicating that
material is shared under a Creative Commons public license or as
otherwise permitted by the Creative Commons policies published at
creativecommons.org/policies, Creative Commons does not authorize the
use of the trademark "Creative Commons" or any other trademark or logo
of Creative Commons without its prior written consent including,
without limitation, in connection with any unauthorized modifications
to any of its public licenses or any other arrangements,
understandings, or agreements concerning use of licensed material. For
the avoidance of doubt, this paragraph does not form part of the
public licenses.

Creative Commons may be contacted at creativecommons.org.

===============================================================================


    * Package Arm Performance Libraries's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/armpl/AmazonLinux-2/arm-performance-
libraries_24.10_rpm_gcc.tar

SIMPLIFIED END USER LICENSE AGREEMENT FOR FREE OF CHARGE ARM REDISTRIBUTABLES

This end user license agreement ("License") is a legal agreement between you (a
single individual), or the company or organisation (a single legal entity) that
you represent and have the legal authority to bind, and Arm relating to use of
the Arm Tools. By clicking "I Agree" or by installing or otherwise using the Arm
Tools you indicate that you agree to be bound by all of the terms and conditions
of this License.

DEFINITIONS
For the purposes of this License the following words and expressions shall have
the following meanings:
"Arm" means Arm Limited whose registered office is situated at 110 Fulbourn
Road, Cambridge CB1 9NJ, England and/or any member of Arm's group of companies.
"Arm Tools" means any and all software, firmware, data and associated
documentation licensed to you by Arm under this License and any Updates thereto.
"Third Party Licenses File" means a software file or folder typically named
'third_party_licenses' located within the 'license_terms' folder in an Arm Tool
(or components thereof) which (if applicable) details any third party material
included in the relevant Arm Tool which is not licensed under the terms of this
License, and a reference to the applicable third party license terms and
conditions.
"Update" means an update, patch, hotfix, bug fix, support release, modification
or limited functional enhancement (as applicable) to an Arm Tool or component
thereof, including but not limited to error corrections to any program or
associated documentation developed by or for Arm comprised in the Arm Tools,
which (i) Arm makes generally available to the market, and (ii) does not, in
Arm's opinion, constitute an upgrade or a new product.
"Your Hardware" means hardware manufactured or developed by you or on your
behalf, or hardware owned or licensed by you, which is supported by the Arm
Tools.
"Your Reports" means any written reports or other information relating to the
behavior or performance of Your Software or Your Hardware, in html, binary, text
or any other format, generated by you from or using the Arm Tools and any
modifications thereto.
"Your Software" means any software owned or licensed by you (including, but not
limited to, applications, libraries and Arm API compliant plug-ins, but
excluding Arm Tools) which is supported by (or developed by you using) the Arm
Tools.

1.      LICENSE GRANT
1.1     Subject to your compliance with the terms and conditions of this License
Arm hereby grants to you a license to use the Arm Tools (or components thereof)
for the purpose of:
(a) building, developing, testing, debugging, analysing and optimising Your
Software or Your Hardware; and
(b) generation of Your Reports, and use of Your Reports to develop, test, debug,
analyse and optimise Your Software or Your Hardware; and
(c) incorporating, compiling and/or linking the Arm Tool or components thereof
into Your Software, provided that Your Software contains substantial additional
functionality; and (ii) subject to clause 2.1 below, reproducing and
redistributing the Arm Tool or components thereof (and permitting your customers
and/or your authorised distributors to reproduce and redistribute the
components), only in object code form, and only as part of Your Software. You
may only copy the Arm Tools (or any component thereof) to the extent that such
copying is incidental to the permitted uses set out in this clause 1.1,
including installation, backup and execution.
1.2     Arm shall not be obligated to provide any support, Updates or other
maintenance in respect of the Arm Tools.

2.      YOUR OBLIGATIONS AND RESTRICTIONS ON USE
2.1     Any redistribution as permitted by this License is subject to your
compliance with the following:
(a)     You are responsible for ensuring that such customers, authorised
distributors and third parties accept, and are contractually bound (by agreement
with you or directly with Arm) to comply with, the terms and conditions of this
License;
(b)     Any use by you of Arm's or any of its licensors' names, logos or
trademarks to publicise or market any of Your Software containing (or developed
or generated using) Arm Tools is subject to you obtaining express written
permission from Arm;
(c)     You warrant that you shall not make any representations or warranties on
behalf of Arm in respect of any of the Arm Tools or in respect of any other
software, reports or documentation developed or generated by you in accordance
with the license grants set out in this License; and
(d)     You must reproduce or preserve (as applicable) any copyright notices
which are included in or with any Arm Tools or components thereof.
2.2     Your use of the Arm Tools shall specifically exclude the reverse
engineering, decompiling, disassembly, translation, adaptation, arrangement or
other alteration of any part of the Arm Tools (except to the extent that
applicable law overrides this provision or any part hereof).
2.3     The Arm Tools are owned by Arm and/or its licensors and are protected by
copyright and other intellectual property rights, laws and international
treaties. The Arm Tools are licensed not sold. Except as expressly provided by
this License, you acquire no rights to the Arm Tools or any element thereof, or
to any other Arm products or services. You shall not remove from the Arm Tools
any copyright notice or other notice (including this License) and shall ensure
that any such notice is reproduced in any reproduction of the whole or any part
of the Arm Tools.
2.4     You agree not to circumvent or work around any feature, key or other
licensing control mechanism included in an Arm Tool that ensures your use is
consistent with the keys or features that you have licensed from Arm under this
License.
2.5     You may use Arm documentation (if any) internally only in conjunction
with your use of the Arm software to which it relates.

3. LICENSE OF FEEDBACK TO ARM
You may at your discretion deliver any suggestions, comments, feedback, ideas,
or know-how (whether in oral or written form) to Arm relating to or connected
with your use of the Arm Tools ("Feedback"). Notwithstanding the foregoing, you
shall not knowingly give to Arm any Feedback that you are aware (or should
reasonably be aware) is subject to any patent, copyright or other intellectual
property claim or right of any third party. Except as expressly notified by you
to Arm (in writing which may include email) to the contrary, you hereby grant to
Arm under your and your affiliates (as applicable) intellectual property, a
perpetual, irrevocable, royalty free, non-exclusive, worldwide license to: (i)
use, copy, modify, and create derivative works of the Feedback; (ii) sell,
supply or otherwise distribute the whole or any part of the Feedback (and
derivative works thereof) as part of any Arm owned or licensed product(s)
without obligation or restriction of any kind; and (iii) sub-license to third
parties the foregoing rights, including the right to sub-license to further
third parties. No right is granted by you to Arm to sub-license your and your
affiliates (as applicable) intellectual property except to the extent that it is
provided to Arm as Feedback and is embodied in any Arm owned or licensed
product(s). For the avoidance of doubt, if, during the term of this License, you
provide notice to Arm revoking the license granted under this clause 3, you
acknowledge and agree that such revocation shall not apply to Feedback delivered
to Arm prior to the date of receipt of the revocation notice, and that
(notwithstanding the foregoing) Arm shall continue to be permitted to use
Feedback received after the date of receipt of the revocation notice for
internal purposes. Except as expressly licensed to Arm in this clause 3, you
retain all right, title and interest in and to the Feedback provided by you
under this License.

4.      DISCLAIMER
4.1     YOU AGREE THAT THE ARM TOOLS ARE LICENSED "AS IS", AND THAT ARM
EXPRESSLY DISCLAIMS ALL REPRESENTATIONS, WARRANTIES, CONDITIONS OR OTHER TERMS,
EXPRESS OR IMPLIED OR STATUTORY, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, SATISFACTORY QUALITY, AND FITNESS FOR A
PARTICULAR PURPOSE. YOU ACKNOWLEDGE THAT IT IS YOUR RESPONSIBILITY TO SATISFY
YOURSELF THAT THE ARM TOOLS ARE FIT FOR THE INTENDED PURPOSE AND SATISFY YOUR
REQUIREMENTS, INCLUDING COMPATIBILITY WITH YOUR HARDWARE, AND YOU EXPRESSLY
ASSUME ALL LIABILITIES AND RISKS RELATING TO (I) ANY USE OF AN ARM TOOL WHICH IS
INCONSISTENT WITH ITS DESIGN OR ANY GUIDANCE PROVIDED TO YOU IN ANY APPLICABLE
DOCUMENTATION ACCOMPANYING THE SOFTWARE, AND/OR (II) ANY USE OF AN ARM TOOL WITH
YOUR SOFTWARE OR YOUR HARDWARE WHERE SUCH SOFTWARE OR HARDWARE (AS APPLICABLE)
IS NOT SUPPORTED BY OR COMPATIBLE WITH THE RELEVANT ARM TOOL.
4.2     You expressly assume all liabilities and risks relating to your use or
operation of Your Software and Your Hardware designed or modified using the Arm
Tools, including without limitation, Your software or Your Hardware designed or
intended for safety-critical applications. Should Your Software or Your Hardware
prove defective, you assume the entire cost of all necessary servicing, repair
or correction.

5.       LIMITATION OF LIABILITY
5.1     TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL ARM
BE LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
(INCLUDING LOSS OF PROFITS) ARISING OUT OF THE USE OF, OR INABILITY TO USE, THE
ARM TOOLS, WHETHER BASED ON A CLAIM UNDER CONTRACT, TORT OR OTHERWISE, EVEN IF
ARM WAS ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
5.2     Arm does not seek to limit or exclude liability for death or personal
injury arising from Arm's negligence or Arm's fraud. Arm acknowledges that
certain jurisdictions do not permit the exclusion or limitation of liability for
consequential or incidental damages, and in such cases the above limitation
relating to liability for consequential damages may not apply to you.
5.3     NOTWITHSTANDING ANYTHING TO THE CONTRARY CONTAINED IN THIS LICENSE, THE
MAXIMUM LIABILITY OF ARM TO YOU IN AGGREGATE (IN CONTRACT, TORT OR OTHERWISE) IN
RELATION TO OR IN CONNECTION WITH THE SUBJECT MATTER OF THIS LICENSE SHALL NOT
EXCEED THE GREATER OF (I) THE TOTAL SUMS PAID BY YOU TO ARM (IF ANY) FOR THIS
LICENSE, AND (II) $10.00 USD. THE EXISTENCE OF MORE THAN ONE CLAIM WILL NOT
ENLARGE OR EXTEND THE LIMIT.

6.      THIRD PARTY MATERIAL
6.1     The Arm Tools may contain material owned or developed by third parties,
including but not limited to open source software, freeware and commercial
software ("Third Party Material"). Details relating to such Third Party Material
shall either be presented to you at the time of installation or shall be
detailed in the Third Party Licenses File(s). Your use of such Third Party
Material is subject to your compliance with the applicable Third Party Material
license(s) and such Third Party Material is not covered by this License.
6.2     Arm hereby disclaims any and all warranties express or implied from any
third parties regarding, or otherwise connected with, any Third Party Material
included in the Arm Tools and any Third Party Material from which the Arm Tools
are derived, and/or your use of any or all of the Third Party Material in
connection with Your Software or Your Hardware, including (without limitation)
any warranties of satisfactory quality or fitness for a particular purpose.
6.3     No Third Party Material licensors shall have any liability for any
direct, indirect, incidental, special, exemplary, or consequential damages
(including without limitation lost profits) howsoever caused and whether made
under contract, tort or otherwise arising in any way out of your use or
distribution of the Third Party Material or the exercise of any rights granted
under either or both this License and the legal terms applicable to any Third
Party Material, even if advised in advance of the possibility of such damages.

7.      TERM AND TERMINATION
7.1     Subject to clauses 7.2 and 7.3 below, this License shall remain in force
until terminated by you or Arm.
7.2     Arm may terminate this License at any time for any reason by giving
written notice to you.
7.3     In the event of a party breaching of any of the terms and conditions of
this License, which if capable of remedy, has not been remedied by that party
within thirty (30) days of the date of breach, without prejudice to any of its
other rights under this License, the non-breaching party may terminate this
License immediately upon giving written notice to the breaching party. Upon
termination of this License by you or by Arm you shall immediately (i) stop
using the Arm Tools (or any element thereof) and, (ii) destroy all copies of the
same in your possession or control.
7.4     Notwithstanding the foregoing, except where Arm has terminated this
License for your breach, your rights (if applicable) to distribute any of Your
Software or Your Hardware developed prior to termination of this License, either
(i) developed using the Arm Tools; or incorporating or linking to the Arm Tools
or components thereof (as permitted by this License) shall, subject to your
continued compliance with the terms and conditions of this License, survive such
termination.
 7.5    Upon termination of this License, the provisions of clauses 2 to 8 of
this License shall survive.

8.      GENERAL
8.1     This License is governed by English Law. Notwithstanding the foregoing,
to the extent that you are an agency, contractor or instrumentality of the U.S.
Government, disputes arising under or relating to this License shall be decided
under the U.S. federal law of government contracting, including without
limitation the Contract Disputes Act. Nothing in this License shall prevent you
from enforcing your intellectual property rights or seeking injunctive or other
equitable relief in any court of competent jurisdiction. The parties hereby
disclaim application of the United Nations Convention on Contracts for the
International Sale of Goods and the Uniform Computer Information Transactions
Act.
8.2     Except where Arm agrees otherwise in (i) a written contract signed by
you and Arm, or (ii) a written contract provided by Arm and accepted by you,
this is the only agreement between you and Arm relating to the Arm Tools and it
may only be modified by written agreement between you and Arm. No terms and
conditions contained in any purchase order or other document issued by you, or
any advertising or other representation by you or any third party shall add to,
supersede or in any way vary the terms and conditions of this License. This
License (and any documents expressly incorporated into it by reference herein)
represents the entire agreement between you and Arm in relation to its subject
matter.
8.3     If any clause or sentence in this License is held by a court of law to
be illegal or unenforceable, the remaining provisions of this License shall not
be affected. Any failure by Arm to enforce any of the provisions of this
License, unless waived in writing, shall not constitute a waiver of Arm's rights
to enforce such provision or any other provision of this License in the future.

Arm document version 1.0, effective 24 June 2020
```

---

## Slurm; version 25.11.4-1

<https://github.com/SchedMD/slurm>

```text

    * Package Slurm's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.amazonaws.com/archives/dependenci
es/slurm/slurm-25-11-4-1.tar.gz

                         SLURM LICENSE AGREEMENT

All Slurm code and documentation is available under the GNU General Public
License. Some tools in the "contribs" directory have other licenses. See
the documentation for individual contributed tools for details.

In addition, as a special exception, the copyright holders give permission
to link the code of portions of this program with the OpenSSL library under
certain conditions as described in each individual source file, and distribute
linked combinations including the two. You must obey the GNU General Public
License in all respects for all of the code used other than OpenSSL. If you
modify file(s) with this exception, you may extend this exception to your
version of the file(s), but you are not obligated to do so. If you do not
wish to do so, delete this exception statement from your version. If you
delete this exception statement from all source files in the program, then
also delete it here.

NO WARRANTY: Because the program is licensed free of charge, there is no
warranty for the program. See section 11 below for full details.

=============================================================================

OUR NOTICE AND TERMS OF AND CONDITIONS OF THE GNU GENERAL PUBLIC LICENSE

Auspices

Portions of this work were performed under the auspices of the U.S. Department
of Energy by Lawrence Livermore National Laboratory under Contract
DE-AC52-07NA27344.

Disclaimer

This work was sponsored by an agency of the United States government.
Neither the United States Government nor Lawrence Livermore National
Security, LLC, nor any of their employees, makes any warranty, express
or implied, or assumes any liability or responsibility for the accuracy,
completeness, or usefulness of any information, apparatus, product, or
process disclosed, or represents that its use would not infringe privately
owned rights. References herein to any specific commercial products, process,
or services by trade names, trademark, manufacturer or otherwise does not
necessarily constitute or imply its endorsement, recommendation, or
favoring by the United States Government or the Lawrence Livermore National
Security, LLC. The views and opinions of authors expressed herein do not
necessarily state or reflect those of the United States government or
Lawrence Livermore National Security, LLC, and shall not be used for
advertising or product endorsement purposes.

=============================================================================

                    GNU GENERAL PUBLIC LICENSE
                       Version 2, June 1991

 Copyright (C) 1989, 1991 Free Software Foundation, Inc.
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Library General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

  2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) You must cause the modified files to carry prominent notices
    stating that you changed the files and the date of any change.

    b) You must cause any work that you distribute or publish, that in
    whole or in part contains or is derived from the Program or any
    part thereof, to be licensed as a whole at no charge to all third
    parties under the terms of this License.

    c) If the modified program normally reads commands interactively
    when run, you must cause it, when started running for such
    interactive use in the most ordinary way, to print or display an
    announcement including an appropriate copyright notice and a
    notice that there is no warranty (or else, saying that you provide
    a warranty) and that users may redistribute the program under
    these conditions, and telling the user how to view a copy of this
    License.  (Exception: if the Program itself is interactive but
    does not normally print such an announcement, your work based on
    the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

    a) Accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of Sections
    1 and 2 above on a medium customarily used for software interchange; or,

    b) Accompany it with a written offer, valid for at least three
    years, to give any third party, for a charge no more than your
    cost of physically performing source distribution, a complete
    machine-readable copy of the corresponding source code, to be
    distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange; or,

    c) Accompany it with the information you received as to the offer
    to distribute corresponding source code.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form with such
    an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as a
special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

  4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

  5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

  7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

  9. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
this License, you may choose any version ever published by the Free Software
Foundation.

  10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
convey the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
USA


Also add information on how to contact you by electronic and paper mail.

If the program is interactive, make it output a short notice like this
when it starts in an interactive mode:

    Gnomovision version 69, Copyright (C) year name of author
    Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, the commands you use may
be called something other than `show w' and `show c'; they could even be
mouse-clicks or menu items--whatever suits your program.

You should also get your employer (if you work as a programmer) or your
school, if any, to sign a "copyright disclaimer" for the program, if
necessary.  Here is a sample; alter the names:

  Yoyodyne, Inc., hereby disclaims all copyright interest in the program
  `Gnomovision' (which makes passes at compilers) written by James Hacker.

  <signature of Ty Coon>, 1 April 1989
  Ty Coon, President of Vice

This General Public License does not permit incorporating your program into
proprietary programs.  If your program is a subroutine library, you may
consider it more useful to permit linking proprietary applications with the
library.  If this is what you want to do, use the GNU Library General
Public License instead of this License.

/*
 * (c) 2002, 2003, 2004 by Jason McLaughlin and Riadh Elloumi
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * is provided AS IS, WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, and
 * NON-INFRINGEMENT.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA.
 *
 * In addition, as a special exception, the copyright holders give
 * permission to link the code of portions of this program with the
 * OpenSSL library under certain conditions as described in each
 * individual source file, and distribute linked combinations
 * including the two.
 * You must obey the GNU General Public License in all respects
 * for all of the code used other than OpenSSL.  If you modify
 * file(s) with this exception, you may extend this exception to your
 * version of the file(s), but you are not obligated to do so.  If you
 * do not wish to do so, delete this exception statement from your
 * version.  If you delete this exception statement from all source
 * files in the program, then also delete it here.
 */

Certain source files in this program permit linking with the OpenSSL
library (http://www.openssl.org), which otherwise wouldn't be allowed
under the GPL.  For purposes of identifying OpenSSL, most source files
giving this permission limit it to versions of OpenSSL having a license
identical to that listed in this file (LICENSE.OpenSSL).  It is not
necessary for the copyright years to match between this file and the
OpenSSL version in question.  However, note that because this file is
an extension of the license statements of these source files, this file
may not be changed except with permission from all copyright holders
of source files in this program which reference this file.


  LICENSE ISSUES
  ==============

  The OpenSSL toolkit stays under a dual license, i.e. both the conditions of
  the OpenSSL License and the original SSLeay license apply to the toolkit.
  See below for the actual license texts. Actually both licenses are BSD-style
  Open Source licenses. In case of any license issues related to OpenSSL
  please contact openssl-core@openssl.org.

  OpenSSL License
  ---------------

/* ====================================================================
 * Copyright (c) 1998-2001 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.openssl.org/)"
 *
 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    openssl-core@openssl.org.
 *
 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit (http://www.openssl.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This product includes cryptographic software written by Eric Young
 * (eay@cryptsoft.com).  This product includes software written by Tim
 * Hudson (tjh@cryptsoft.com).
 *
 */

 Original SSLeay License
 -----------------------

/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 *
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 *
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from
 *    the apps directory (application code) you must include an acknowledgement:
 *    "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"
 *
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */
```

---

## stunnel; version 5.67

<https://www.stunnel.org/>

```text
Copyright (C) 1998-2019 Michal Trojnara

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, see http://www.gnu.org/licenses.

Linking stunnel statically or dynamically with other modules is making a
combined work based on stunnel. Thus, the terms and conditions of the GNU
General Public License cover the whole combination.

In addition, as a special exception, the copyright holder of stunnel gives you
permission to combine stunnel with free software programs or libraries that are
released under the GNU LGPL and with code included in the standard release of
OpenSSL under the OpenSSL License (or modified versions of such code, with
unchanged license). You may copy and distribute such a system following the
terms of the GNU GPL for stunnel and the licenses of the other code concerned.

Note that people who make modified versions of stunnel are not obligated to
grant this special exception for their modified versions; it is their choice
whether to do so. The GNU General Public License gives permission to release a
modified version without this exception; this exception also makes it possible
to release a modified version which carries forward this exception.

    * Package stunnel's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/stunnel/stunnel-5.67.tar.gz

GNU GENERAL PUBLIC LICENSE
Version 2, June 1991

Copyright (C) 1989, 1991 Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.

Preamble

The licenses for most software are designed to take away your freedom to share
and change it. By contrast, the GNU General Public License is intended to
guarantee your freedom to share and change free software--to make sure the
software is free for all its users. This General Public License applies to most
of the Free Software Foundation's software and to any other program whose
authors commit to using it. (Some other Free Software Foundation software is
covered by the GNU Lesser General Public License instead.) You can apply it to
your programs, too.

When we speak of free software, we are referring to freedom, not price. Our
General Public Licenses are designed to make sure that you have the freedom to
distribute copies of free software (and charge for this service if you wish),
that you receive source code or can get it if you want it, that you can change
the software or use pieces of it in new free programs; and that you know you can
do these things.

To protect your rights, we need to make restrictions that forbid anyone to deny
you these rights or to ask you to surrender the rights. These restrictions
translate to certain responsibilities for you if you distribute copies of the
software, or if you modify it.

For example, if you distribute copies of such a program, whether gratis or for a
fee, you must give the recipients all the rights that you have. You must make
sure that they, too, receive or can get the source code. And you must show them
these terms so they know their rights.

We protect your rights with two steps: (1) copyright the software, and (2) offer
you this license which gives you legal permission to copy, distribute and/or
modify the software.

Also, for each author's protection and ours, we want to make certain that
everyone understands that there is no warranty for this free software. If the
software is modified by someone else and passed on, we want its recipients to
know that what they have is not the original, so that any problems introduced by
others will not reflect on the original authors' reputations.

Finally, any free program is threatened constantly by software patents. We wish
to avoid the danger that redistributors of a free program will individually
obtain patent licenses, in effect making the program proprietary. To prevent
this, we have made it clear that any patent must be licensed for everyone's free
use or not licensed at all.

The precise terms and conditions for copying, distribution and modification
follow.

TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. This License applies to any program or other work which contains a notice
placed by the copyright holder saying it may be distributed under the terms of
this General Public License. The "Program", below, refers to any such program or
work, and a "work based on the Program" means either the Program or any
derivative work under copyright law: that is to say, a work containing the
Program or a portion of it, either verbatim or with modifications and/or
translated into another language. (Hereinafter, translation is included without
limitation in the term "modification".) Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not covered by
this License; they are outside its scope. The act of running the Program is not
restricted, and the output from the Program is covered only if its contents
constitute a work based on the Program (independent of having been made by
running the Program). Whether that is true depends on what the Program does.

1. You may copy and distribute verbatim copies of the Program's source code as
you receive it, in any medium, provided that you conspicuously and appropriately
publish on each copy an appropriate copyright notice and disclaimer of warranty;
keep intact all the notices that refer to this License and to the absence of any
warranty; and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and you may at
your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion of it, thus
forming a work based on the Program, and copy and distribute such modifications
or work under the terms of Section 1 above, provided that you also meet all of
these conditions:

     a) You must cause the modified files to carry prominent notices stating
that you changed the files and the date of any change.

     b) You must cause any work that you distribute or publish, that in whole or
in part contains or is derived from the Program or any part thereof, to be
licensed as a whole at no charge to all third parties under the terms of this
License.

     c) If the modified program normally reads commands interactively when run,
you must cause it, when started running for such interactive use in the most
ordinary way, to print or display an announcement including an appropriate
copyright notice and a notice that there is no warranty (or else, saying that
you provide a warranty) and that users may redistribute the program under these
conditions, and telling the user how to view a copy of this License. (Exception:
if the Program itself is interactive but does not normally print such an
announcement, your work based on the Program is not required to print an
announcement.)

These requirements apply to the modified work as a whole. If identifiable
sections of that work are not derived from the Program, and can be reasonably
considered independent and separate works in themselves, then this License, and
its terms, do not apply to those sections when you distribute them as separate
works. But when you distribute the same sections as part of a whole which is a
work based on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the entire whole,
and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest your
rights to work written entirely by you; rather, the intent is to exercise the
right to control the distribution of derivative or collective works based on the
Program.

In addition, mere aggregation of another work not based on the Program with the
Program (or with a work based on the Program) on a volume of a storage or
distribution medium does not bring the other work under the scope of this
License.

3. You may copy and distribute the Program (or a work based on it, under Section
2) in object code or executable form under the terms of Sections 1 and 2 above
provided that you also do one of the following:

     a) Accompany it with the complete corresponding machine-readable source
code, which must be distributed under the terms of Sections 1 and 2 above on a
medium customarily used for software interchange; or,

     b) Accompany it with a written offer, valid for at least three years, to
give any third party, for a charge no more than your cost of physically
performing source distribution, a complete machine-readable copy of the
corresponding source code, to be distributed under the terms of Sections 1 and 2
above on a medium customarily used for software interchange; or,

     c) Accompany it with the information you received as to the offer to
distribute corresponding source code. (This alternative is allowed only for
noncommercial distribution and only if you received the program in object code
or executable form with such an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for making
modifications to it. For an executable work, complete source code means all the
source code for all modules it contains, plus any associated interface
definition files, plus the scripts used to control compilation and installation
of the executable. However, as a special exception, the source code distributed
need not include anything that is normally distributed (in either source or
binary form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component itself
accompanies the executable.

If distribution of executable or object code is made by offering access to copy
from a designated place, then offering equivalent access to copy the source code
from the same place counts as distribution of the source code, even though third
parties are not compelled to copy the source along with the object code.

4. You may not copy, modify, sublicense, or distribute the Program except as
expressly provided under this License. Any attempt otherwise to copy, modify,
sublicense or distribute the Program is void, and will automatically terminate
your rights under this License. However, parties who have received copies, or
rights, from you under this License will not have their licenses terminated so
long as such parties remain in full compliance.

5. You are not required to accept this License, since you have not signed it.
However, nothing else grants you permission to modify or distribute the Program
or its derivative works. These actions are prohibited by law if you do not
accept this License. Therefore, by modifying or distributing the Program (or any
work based on the Program), you indicate your acceptance of this License to do
so, and all its terms and conditions for copying, distributing or modifying the
Program or works based on it.

6. Each time you redistribute the Program (or any work based on the Program),
the recipient automatically receives a license from the original licensor to
copy, distribute or modify the Program subject to these terms and conditions.
You may not impose any further restrictions on the recipients' exercise of the
rights granted herein. You are not responsible for enforcing compliance by third
parties to this License.

7. If, as a consequence of a court judgment or allegation of patent infringement
or for any other reason (not limited to patent issues), conditions are imposed
on you (whether by court order, agreement or otherwise) that contradict the
conditions of this License, they do not excuse you from the conditions of this
License. If you cannot distribute so as to satisfy simultaneously your
obligations under this License and any other pertinent obligations, then as a
consequence you may not distribute the Program at all. For example, if a patent
license would not permit royalty-free redistribution of the Program by all those
who receive copies directly or indirectly through you, then the only way you
could satisfy both it and this License would be to refrain entirely from
distribution of the Program.

If any portion of this section is held invalid or unenforceable under any
particular circumstance, the balance of the section is intended to apply and the
section as a whole is intended to apply in other circumstances.

It is not the purpose of this section to induce you to infringe any patents or
other property right claims or to contest validity of any such claims; this
section has the sole purpose of protecting the integrity of the free software
distribution system, which is implemented by public license practices. Many
people have made generous contributions to the wide range of software
distributed through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing to
distribute software through any other system and a licensee cannot impose that
choice.

This section is intended to make thoroughly clear what is believed to be a
consequence of the rest of this License.

8. If the distribution and/or use of the Program is restricted in certain
countries either by patents or by copyrighted interfaces, the original copyright
holder who places the Program under this License may add an explicit
geographical distribution limitation excluding those countries, so that
distribution is permitted only in or among countries not thus excluded. In such
case, this License incorporates the limitation as if written in the body of this
License.

9. The Free Software Foundation may publish revised and/or new versions of the
General Public License from time to time. Such new versions will be similar in
spirit to the present version, but may differ in detail to address new problems
or concerns.

Each version is given a distinguishing version number. If the Program specifies
a version number of this License which applies to it and "any later version",
you have the option of following the terms and conditions either of that version
or of any later version published by the Free Software Foundation. If the
Program does not specify a version number of this License, you may choose any
version ever published by the Free Software Foundation.

10. If you wish to incorporate parts of the Program into other free programs
whose distribution conditions are different, write to the author to ask for
permission. For software which is copyrighted by the Free Software Foundation,
write to the Free Software Foundation; we sometimes make exceptions for this.
Our decision will be guided by the two goals of preserving the free status of
all derivatives of our free software and of promoting the sharing and reuse of
software generally.

NO WARRANTY

11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED
IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS
IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT
NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL,
SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY
TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF
THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER
PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS

How to Apply These Terms to Your New Programs

If you develop a new program, and you want it to be of the greatest possible use
to the public, the best way to achieve this is to make it free software which
everyone can redistribute and change under these terms.

To do so, attach the following notices to the program. It is safest to attach
them to the start of each source file to most effectively convey the exclusion
of warranty; and each file should have at least the "copyright" line and a
pointer to where the full notice is found.

     one line to give the program's name and an idea of what it does. Copyright
(C) yyyy name of author

     This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

     This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

     You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. Also add information
on how to contact you by electronic and paper mail.

If the program is interactive, make it output a short notice like this when it
starts in an interactive mode:

     Gnomovision version 69, Copyright (C) year name of author Gnomovision comes
with ABSOLUTELY NO WARRANTY; for details type `show w'. This is free software,
and you are welcome to redistribute it under certain conditions; type `show c'
for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License. Of course, the commands you use may be
called something other than `show w' and `show c'; they could even be mouse-
clicks or menu items--whatever suits your program.

You should also get your employer (if you work as a programmer) or your school,
if any, to sign a "copyright disclaimer" for the program, if necessary. Here is
a sample; alter the names:

     Yoyodyne, Inc., hereby disclaims all copyright interest in the program
`Gnomovision' (which makes passes at compilers) written by James Hacker.

signature of Ty Coon, 1 April 1989 Ty Coon, President of Vice
```

---

## MUNGE; version 0.5.18

<https://github.com/dun/munge/archive/refs/tags/munge-0.5.18.tar.gz>

```text
Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

    * Package MUNGE's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/munge/munge-0.5.18.tar.gz

                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.
```

---

## gcc; version 11.3.0, 9.3.0

<https://ftp.gnu.org/gnu/gcc/gcc-11.3.0/>

```text
This GCC Runtime Library Exception ("Exception") is an additional
permission under section 7 of the GNU General Public License, version
3 ("GPLv3"). It applies to a given file (the "Runtime Library") that
bears a notice placed by the copyright holder of the file stating that
the file is governed by GPLv3 along with this Exception.

When you use GCC to compile a program, GCC may combine portions of
certain GCC header files and runtime libraries with the compiled
program. The purpose of this Exception is to allow compilation of
non-GPL (including proprietary) programs to use, in this way, the
header files and runtime libraries covered by this Exception.

0. Definitions.

A file is an "Independent Module" if it either requires the Runtime
Library for execution after a Compilation Process, or makes use of an
interface provided by the Runtime Library, but is not otherwise based
on the Runtime Library.

"GCC" means a version of the GNU Compiler Collection, with or without
modifications, governed by version 3 (or a specified later version) of
the GNU General Public License (GPL) with the option of using any
subsequent versions published by the FSF.

"GPL-compatible Software" is software whose conditions of propagation,
modification and use would permit combination with GCC in accord with
the license of GCC.

"Target Code" refers to output from any compiler for a real or virtual
target processor architecture, in executable form or suitable for
input to an assembler, loader, linker and/or execution
phase. Notwithstanding that, Target Code does not include data in any
format that is used as a compiler intermediate representation, or used
for producing a compiler intermediate representation.

The "Compilation Process" transforms code entirely represented in
non-intermediate languages designed for human-written code, and/or in
Java Virtual Machine byte code, into Target Code. Thus, for example,
use of source code generators and preprocessors need not be considered
part of the Compilation Process, since the Compilation Process can be
understood as starting with the output of the generators or
preprocessors.

A Compilation Process is "Eligible" if it is done using GCC, alone or
with other GPL-compatible software, or if it is done without using any
work based on GCC. For example, using non-GPL-compatible Software to
optimize any GCC intermediate representations would not qualify as an
Eligible Compilation Process.

1. Grant of Additional Permission.

You have permission to propagate a work of Target Code formed by
combining the Runtime Library with Independent Modules, even if such
propagation would otherwise violate the terms of GPLv3, provided that
all Target Code was generated by Eligible Compilation Processes. You
may then convey such a combination under terms of your choice,
consistent with the licensing of the Independent Modules.

2. No Weakening of GCC Copyleft.

The availability of this Exception does not imply any general
presumption that third-party software is unaffected by the copyleft
requirements of the license of GCC.

    * Package gcc's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/gcc/gcc-11.3.0.tar.gz

Version 3, 29 June 2007

Copyright © 2007 Free Software Foundation, Inc. https://www.fsf.org

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.

Preamble
The GNU General Public License is a free, copyleft license for software and
other kinds of works.

The licenses for most software and other practical works are designed to take
away your freedom to share and change the works. By contrast, the GNU General
Public License is intended to guarantee your freedom to share and change all
versions of a program—to make sure it remains free software for all its users.
We, the Free Software Foundation, use the GNU General Public License for most of
our software; it applies also to any other work released this way by its
authors. You can apply it to your programs, too.

When we speak of free software, we are referring to freedom, not price. Our
General Public Licenses are designed to make sure that you have the freedom to
distribute copies of free software (and charge for them if you wish), that you
receive source code or can get it if you want it, that you can change the
software or use pieces of it in new free programs, and that you know you can do
these things.

To protect your rights, we need to prevent others from denying you these rights
or asking you to surrender the rights. Therefore, you have certain
responsibilities if you distribute copies of the software, or if you modify it:
responsibilities to respect the freedom of others.

For example, if you distribute copies of such a program, whether gratis or for a
fee, you must pass on to the recipients the same freedoms that you received. You
must make sure that they, too, receive or can get the source code. And you must
show them these terms so they know their rights.

Developers that use the GNU GPL protect your rights with two steps: (1) assert
copyright on the software, and (2) offer you this License giving you legal
permission to copy, distribute and/or modify it.

For the developers’ and authors’ protection, the GPL clearly explains that there
is no warranty for this free software. For both users’ and authors’ sake, the
GPL requires that modified versions be marked as changed, so that their problems
will not be attributed erroneously to authors of previous versions.

Some devices are designed to deny users access to install or run modified
versions of the software inside them, although the manufacturer can do so. This
is fundamentally incompatible with the aim of protecting users’ freedom to
change the software. The systematic pattern of such abuse occurs in the area of
products for individuals to use, which is precisely where it is most
unacceptable. Therefore, we have designed this version of the GPL to prohibit
the practice for those products. If such problems arise substantially in other
domains, we stand ready to extend this provision to those domains in future
versions of the GPL, as needed to protect the freedom of users.

Finally, every program is threatened constantly by software patents. States
should not allow patents to restrict development and use of software on general-
purpose computers, but in those that do, we wish to avoid the special danger
that patents applied to a free program could make it effectively proprietary. To
prevent this, the GPL assures that patents cannot be used to render the program
non-free.

The precise terms and conditions for copying, distribution and modification
follow.

TERMS AND CONDITIONS
0. Definitions.
“This License” refers to version 3 of the GNU General Public License.

“Copyright” also means copyright-like laws that apply to other kinds of works,
such as semiconductor masks.

“The Program” refers to any copyrightable work licensed under this License. Each
licensee is addressed as “you”. “Licensees” and “recipients” may be individuals
or organizations.

To “modify” a work means to copy from or adapt all or part of the work in a
fashion requiring copyright permission, other than the making of an exact copy.
The resulting work is called a “modified version” of the earlier work or a work
“based on” the earlier work.

A “covered work” means either the unmodified Program or a work based on the
Program.

To “propagate” a work means to do anything with it that, without permission,
would make you directly or secondarily liable for infringement under applicable
copyright law, except executing it on a computer or modifying a private copy.
Propagation includes copying, distribution (with or without modification),
making available to the public, and in some countries other activities as well.

To “convey” a work means any kind of propagation that enables other parties to
make or receive copies. Mere interaction with a user through a computer network,
with no transfer of a copy, is not conveying.

An interactive user interface displays “Appropriate Legal Notices” to the extent
that it includes a convenient and prominently visible feature that (1) displays
an appropriate copyright notice, and (2) tells the user that there is no
warranty for the work (except to the extent that warranties are provided), that
licensees may convey the work under this License, and how to view a copy of this
License. If the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

1. Source Code.
The “source code” for a work means the preferred form of the work for making
modifications to it. “Object code” means any non-source form of a work.

A “Standard Interface” means an interface that either is an official standard
defined by a recognized standards body, or, in the case of interfaces specified
for a particular programming language, one that is widely used among developers
working in that language.

The “System Libraries” of an executable work include anything, other than the
work as a whole, that (a) is included in the normal form of packaging a Major
Component, but which is not part of that Major Component, and (b) serves only to
enable use of the work with that Major Component, or to implement a Standard
Interface for which an implementation is available to the public in source code
form. A “Major Component”, in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system (if any) on
which the executable work runs, or a compiler used to produce the work, or an
object code interpreter used to run it.

The “Corresponding Source” for a work in object code form means all the source
code needed to generate, install, and (for an executable work) run the object
code and to modify the work, including scripts to control those activities.
However, it does not include the work’s System Libraries, or general-purpose
tools or generally available free programs which are used unmodified in
performing those activities but which are not part of the work. For example,
Corresponding Source includes interface definition files associated with source
files for the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require, such as by
intimate data communication or control flow between those subprograms and other
parts of the work.

The Corresponding Source need not include anything that users can regenerate
automatically from other parts of the Corresponding Source.

The Corresponding Source for a work in source code form is that same work.

2. Basic Permissions.
All rights granted under this License are granted for the term of copyright on
the Program, and are irrevocable provided the stated conditions are met. This
License explicitly affirms your unlimited permission to run the unmodified
Program. The output from running a covered work is covered by this License only
if the output, given its content, constitutes a covered work. This License
acknowledges your rights of fair use or other equivalent, as provided by
copyright law.

You may make, run and propagate covered works that you do not convey, without
conditions so long as your license otherwise remains in force. You may convey
covered works to others for the sole purpose of having them make modifications
exclusively for you, or provide you with facilities for running those works,
provided that you comply with the terms of this License in conveying all
material for which you do not control copyright. Those thus making or running
the covered works for you must do so exclusively on your behalf, under your
direction and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

Conveying under any other circumstances is permitted solely under the conditions
stated below. Sublicensing is not allowed; section 10 makes it unnecessary.

3. Protecting Users’ Legal Rights From Anti-Circumvention Law.
No covered work shall be deemed part of an effective technological measure under
any applicable law fulfilling obligations under article 11 of the WIPO copyright
treaty adopted on 20 December 1996, or similar laws prohibiting or restricting
circumvention of such measures.

When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention is
effected by exercising rights under this License with respect to the covered
work, and you disclaim any intention to limit operation or modification of the
work as a means of enforcing, against the work’s users, your or third parties’
legal rights to forbid circumvention of technological measures.

4. Conveying Verbatim Copies.
You may convey verbatim copies of the Program’s source code as you receive it,
in any medium, provided that you conspicuously and appropriately publish on each
copy an appropriate copyright notice; keep intact all notices stating that this
License and any non-permissive terms added in accord with section 7 apply to the
code; keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

You may charge any price or no price for each copy that you convey, and you may
offer support or warranty protection for a fee.

5. Conveying Modified Source Versions.
You may convey a work based on the Program, or the modifications to produce it
from the Program, in the form of source code under the terms of section 4,
provided that you also meet all of these conditions:

The work must carry prominent notices stating that you modified it, and giving a
relevant date.

The work must carry prominent notices stating that it is released under this
License and any conditions added under section 7. This requirement modifies the
requirement in section 4 to “keep intact all notices”.

You must license the entire work, as a whole, under this License to anyone who
comes into possession of a copy. This License will therefore apply, along with
any applicable section 7 additional terms, to the whole of the work, and all its
parts, regardless of how they are packaged. This License gives no permission to
license the work in any other way, but it does not invalidate such permission if
you have separately received it.

If the work has interactive user interfaces, each must display Appropriate Legal
Notices; however, if the Program has interactive interfaces that do not display
Appropriate Legal Notices, your work need not make them do so.

A compilation of a covered work with other separate and independent works, which
are not by their nature extensions of the covered work, and which are not
combined with it such as to form a larger program, in or on a volume of a
storage or distribution medium, is called an “aggregate” if the compilation and
its resulting copyright are not used to limit the access or legal rights of the
compilation’s users beyond what the individual works permit. Inclusion of a
covered work in an aggregate does not cause this License to apply to the other
parts of the aggregate.

6. Conveying Non-Source Forms.
You may convey a covered work in object code form under the terms of sections 4
and 5, provided that you also convey the machine-readable Corresponding Source
under the terms of this License, in one of these ways:

Convey the object code in, or embodied in, a physical product (including a
physical distribution medium), accompanied by the Corresponding Source fixed on
a durable physical medium customarily used for software interchange.

Convey the object code in, or embodied in, a physical product (including a
physical distribution medium), accompanied by a written offer, valid for at
least three years and valid for as long as you offer spare parts or customer
support for that product model, to give anyone who possesses the object code
either (1) a copy of the Corresponding Source for all the software in the
product that is covered by this License, on a durable physical medium
customarily used for software interchange, for a price no more than your
reasonable cost of physically performing this conveying of source, or (2) access
to copy the Corresponding Source from a network server at no charge.

Convey individual copies of the object code with a copy of the written offer to
provide the Corresponding Source. This alternative is allowed only occasionally
and noncommercially, and only if you received the object code with such an
offer, in accord with subsection 6b.

Convey the object code by offering access from a designated place (gratis or for
a charge), and offer equivalent access to the Corresponding Source in the same
way through the same place at no further charge. You need not require recipients
to copy the Corresponding Source along with the object code. If the place to
copy the object code is a network server, the Corresponding Source may be on a
different server (operated by you or a third party) that supports equivalent
copying facilities, provided you maintain clear directions next to the object
code saying where to find the Corresponding Source. Regardless of what server
hosts the Corresponding Source, you remain obligated to ensure that it is
available for as long as needed to satisfy these requirements.

Convey the object code using peer-to-peer transmission, provided you inform
other peers where the object code and Corresponding Source of the work are being
offered to the general public at no charge under subsection 6d.

A separable portion of the object code, whose source code is excluded from the
Corresponding Source as a System Library, need not be included in conveying the
object code work.

A “User Product” is either (1) a “consumer product”, which means any tangible
personal property which is normally used for personal, family, or household
purposes, or (2) anything designed or sold for incorporation into a dwelling. In
determining whether a product is a consumer product, doubtful cases shall be
resolved in favor of coverage. For a particular product received by a particular
user, “normally used” refers to a typical or common use of that class of
product, regardless of the status of the particular user or of the way in which
the particular user actually uses, or expects or is expected to use, the
product. A product is a consumer product regardless of whether the product has
substantial commercial, industrial or non-consumer uses, unless such uses
represent the only significant mode of use of the product.

“Installation Information” for a User Product means any methods, procedures,
authorization keys, or other information required to install and execute
modified versions of a covered work in that User Product from a modified version
of its Corresponding Source. The information must suffice to ensure that the
continued functioning of the modified object code is in no case prevented or
interfered with solely because modification has been made.

If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as part of a
transaction in which the right of possession and use of the User Product is
transferred to the recipient in perpetuity or for a fixed term (regardless of
how the transaction is characterized), the Corresponding Source conveyed under
this section must be accompanied by the Installation Information. But this
requirement does not apply if neither you nor any third party retains the
ability to install modified object code on the User Product (for example, the
work has been installed in ROM).

The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates for a
work that has been modified or installed by the recipient, or for the User
Product in which it has been modified or installed. Access to a network may be
denied when the modification itself materially and adversely affects the
operation of the network or violates the rules and protocols for communication
across the network.

Corresponding Source conveyed, and Installation Information provided, in accord
with this section must be in a format that is publicly documented (and with an
implementation available to the public in source code form), and must require no
special password or key for unpacking, reading or copying.

7. Additional Terms.
“Additional permissions” are terms that supplement the terms of this License by
making exceptions from one or more of its conditions. Additional permissions
that are applicable to the entire Program shall be treated as though they were
included in this License, to the extent that they are valid under applicable
law. If additional permissions apply only to part of the Program, that part may
be used separately under those permissions, but the entire Program remains
governed by this License without regard to the additional permissions.

When you convey a copy of a covered work, you may at your option remove any
additional permissions from that copy, or from any part of it. (Additional
permissions may be written to require their own removal in certain cases when
you modify the work.) You may place additional permissions on material, added by
you to a covered work, for which you have or can give appropriate copyright
permission.

Notwithstanding any other provision of this License, for material you add to a
covered work, you may (if authorized by the copyright holders of that material)
supplement the terms of this License with terms:

Disclaiming warranty or limiting liability differently from the terms of
sections 15 and 16 of this License; or

Requiring preservation of specified reasonable legal notices or author
attributions in that material or in the Appropriate Legal Notices displayed by
works containing it; or

Prohibiting misrepresentation of the origin of that material, or requiring that
modified versions of such material be marked in reasonable ways as different
from the original version; or

Limiting the use for publicity purposes of names of licensors or authors of the
material; or

Declining to grant rights under trademark law for use of some trade names,
trademarks, or service marks; or

Requiring indemnification of licensors and authors of that material by anyone
who conveys the material (or modified versions of it) with contractual
assumptions of liability to the recipient, for any liability that these
contractual assumptions directly impose on those licensors and authors.

All other non-permissive additional terms are considered “further restrictions”
within the meaning of section 10. If the Program as you received it, or any part
of it, contains a notice stating that it is governed by this License along with
a term that is a further restriction, you may remove that term. If a license
document contains a further restriction but permits relicensing or conveying
under this License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does not survive
such relicensing or conveying.

If you add terms to a covered work in accord with this section, you must place,
in the relevant source files, a statement of the additional terms that apply to
those files, or a notice indicating where to find the applicable terms.

Additional terms, permissive or non-permissive, may be stated in the form of a
separately written license, or stated as exceptions; the above requirements
apply either way.

8. Termination.
You may not propagate or modify a covered work except as expressly provided
under this License. Any attempt otherwise to propagate or modify it is void, and
will automatically terminate your rights under this License (including any
patent licenses granted under the third paragraph of section 11).

However, if you cease all violation of this License, then your license from a
particular copyright holder is reinstated (a) provisionally, unless and until
the copyright holder explicitly and finally terminates your license, and (b)
permanently, if the copyright holder fails to notify you of the violation by
some reasonable means prior to 60 days after the cessation.

Moreover, your license from a particular copyright holder is reinstated
permanently if the copyright holder notifies you of the violation by some
reasonable means, this is the first time you have received notice of violation
of this License (for any work) from that copyright holder, and you cure the
violation prior to 30 days after your receipt of the notice.

Termination of your rights under this section does not terminate the licenses of
parties who have received copies or rights from you under this License. If your
rights have been terminated and not permanently reinstated, you do not qualify
to receive new licenses for the same material under section 10.

9. Acceptance Not Required for Having Copies.
You are not required to accept this License in order to receive or run a copy of
the Program. Ancillary propagation of a covered work occurring solely as a
consequence of using peer-to-peer transmission to receive a copy likewise does
not require acceptance. However, nothing other than this License grants you
permission to propagate or modify any covered work. These actions infringe
copyright if you do not accept this License. Therefore, by modifying or
propagating a covered work, you indicate your acceptance of this License to do
so.

10. Automatic Licensing of Downstream Recipients.
Each time you convey a covered work, the recipient automatically receives a
license from the original licensors, to run, modify and propagate that work,
subject to this License. You are not responsible for enforcing compliance by
third parties with this License.

An “entity transaction” is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations. If propagation of a covered work results
from an entity transaction, each party to that transaction who receives a copy
of the work also receives whatever licenses to the work the party’s predecessor
in interest had or could give under the previous paragraph, plus a right to
possession of the Corresponding Source of the work from the predecessor in
interest, if the predecessor has it or can get it with reasonable efforts.

You may not impose any further restrictions on the exercise of the rights
granted or affirmed under this License. For example, you may not impose a
license fee, royalty, or other charge for exercise of rights granted under this
License, and you may not initiate litigation (including a cross-claim or
counterclaim in a lawsuit) alleging that any patent claim is infringed by
making, using, selling, offering for sale, or importing the Program or any
portion of it.

11. Patents.
A “contributor” is a copyright holder who authorizes use under this License of
the Program or a work on which the Program is based. The work thus licensed is
called the contributor’s “contributor version”.

A contributor’s “essential patent claims” are all patent claims owned or
controlled by the contributor, whether already acquired or hereafter acquired,
that would be infringed by some manner, permitted by this License, of making,
using, or selling its contributor version, but do not include claims that would
be infringed only as a consequence of further modification of the contributor
version. For purposes of this definition, “control” includes the right to grant
patent sublicenses in a manner consistent with the requirements of this License.

Each contributor grants you a non-exclusive, worldwide, royalty-free patent
license under the contributor’s essential patent claims, to make, use, sell,
offer for sale, import and otherwise run, modify and propagate the contents of
its contributor version.

In the following three paragraphs, a “patent license” is any express agreement
or commitment, however denominated, not to enforce a patent (such as an express
permission to practice a patent or covenant not to sue for patent infringement).
To “grant” such a patent license to a party means to make such an agreement or
commitment not to enforce a patent against the party.

If you convey a covered work, knowingly relying on a patent license, and the
Corresponding Source of the work is not available for anyone to copy, free of
charge and under the terms of this License, through a publicly available network
server or other readily accessible means, then you must either (1) cause the
Corresponding Source to be so available, or (2) arrange to deprive yourself of
the benefit of the patent license for this particular work, or (3) arrange, in a
manner consistent with the requirements of this License, to extend the patent
license to downstream recipients. “Knowingly relying” means you have actual
knowledge that, but for the patent license, your conveying the covered work in a
country, or your recipient’s use of the covered work in a country, would
infringe one or more identifiable patents in that country that you have reason
to believe are valid.

If, pursuant to or in connection with a single transaction or arrangement, you
convey, or propagate by procuring conveyance of, a covered work, and grant a
patent license to some of the parties receiving the covered work authorizing
them to use, propagate, modify or convey a specific copy of the covered work,
then the patent license you grant is automatically extended to all recipients of
the covered work and works based on it.

A patent license is “discriminatory” if it does not include within the scope of
its coverage, prohibits the exercise of, or is conditioned on the non-exercise
of one or more of the rights that are specifically granted under this License.
You may not convey a covered work if you are a party to an arrangement with a
third party that is in the business of distributing software, under which you
make payment to the third party based on the extent of your activity of
conveying the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory patent
license (a) in connection with copies of the covered work conveyed by you (or
copies made from those copies), or (b) primarily for and in connection with
specific products or compilations that contain the covered work, unless you
entered into that arrangement, or that patent license was granted, prior to 28
March 2007.

Nothing in this License shall be construed as excluding or limiting any implied
license or other defenses to infringement that may otherwise be available to you
under applicable patent law.

12. No Surrender of Others’ Freedom.
If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not excuse
you from the conditions of this License. If you cannot convey a covered work so
as to satisfy simultaneously your obligations under this License and any other
pertinent obligations, then as a consequence you may not convey it at all. For
example, if you agree to terms that obligate you to collect a royalty for
further conveying from those to whom you convey the Program, the only way you
could satisfy both those terms and this License would be to refrain entirely
from conveying the Program.

13. Use with the GNU Affero General Public License.
Notwithstanding any other provision of this License, you have permission to link
or combine any covered work with a work licensed under version 3 of the GNU
Affero General Public License into a single combined work, and to convey the
resulting work. The terms of this License will continue to apply to the part
which is the covered work, but the special requirements of the GNU Affero
General Public License, section 13, concerning interaction through a network
will apply to the combination as such.

14. Revised Versions of this License.
The Free Software Foundation may publish revised and/or new versions of the GNU
General Public License from time to time. Such new versions will be similar in
spirit to the present version, but may differ in detail to address new problems
or concerns.

Each version is given a distinguishing version number. If the Program specifies
that a certain numbered version of the GNU General Public License “or any later
version” applies to it, you have the option of following the terms and
conditions either of that numbered version or of any later version published by
the Free Software Foundation. If the Program does not specify a version number
of the GNU General Public License, you may choose any version ever published by
the Free Software Foundation.

If the Program specifies that a proxy can decide which future versions of the
GNU General Public License can be used, that proxy’s public statement of
acceptance of a version permanently authorizes you to choose that version for
the Program.

Later license versions may give you additional or different permissions.
However, no additional obligations are imposed on any author or copyright holder
as a result of your choosing to follow a later version.

15. Disclaimer of Warranty.
THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE
QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE
DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. Limitation of Liability.
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS
PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL,
INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED
INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE
PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY
HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

17. Interpretation of Sections 15 and 16.
If the disclaimer of warranty and limitation of liability provided above cannot
be given local legal effect according to their terms, reviewing courts shall
apply local law that most closely approximates an absolute waiver of all civil
liability in connection with the Program, unless a warranty or assumption of
liability accompanies a copy of the Program in return for a fee.

GCC RUNTIME LIBRARY EXCEPTION

Version 3.1, 31 March 2009

Copyright (C) 2009 Free Software Foundation, Inc.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.
```

---

## MySQL; version 8.4.8 (8.0.39 on AL2, 8.0.45 on Ubuntu 24.04)

<https://www.mysql.com/products/community/>

```text
Copyright (c) 1997, 2025, Oracle and/or its affiliates.

    * Package MySQL's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/mysql/source/mysql-8.4.8.tar.gz
      (AL2 continues to use mysql-8.0.39.tar.gz; Ubuntu 22.04/24.04 install
       libmysqlclient from the distribution's own archive)

Licensing Information User Manual

MySQL 8.4.8 Community

Introduction

   This License Information User Manual contains Oracle's product license
   and other licensing information, including licensing information for
   third-party software which may be included in this distribution of
   MySQL 8.4.8 Community.

   Last updated: November 2025

Licensing Information

   This release of MySQL 8.4.8 Community is brought to you by the MySQL
   team at Oracle. This software is released under version 2 of the GNU
   General Public License (GPLv2), as set forth below, with the following
   additional permissions:

   This distribution of MySQL 8.4.8 Community is designed to work with
   certain software (including but not limited to OpenSSL) that is
   licensed under separate terms, as designated in a particular file or
   component or in the license documentation. Without limiting your rights
   under the GPLv2, the authors of MySQL hereby grant you an additional
   permission to link the program and your derivative works with the
   separately licensed software that they have either included with the
   program or referenced in the documentation.

   This distribution includes the MySQL C API client library
   (libmysqlclient) otherwise known as MySQL Connector/C. Without limiting
   the foregoing grant of rights under the GPLv2 and additional permission
   as to separately licensed software, this Connector is also subject to
   the Universal FOSS Exception, version 1.0, a copy of which is
   reproduced below and can also be found along with its FAQ at
   http://oss.oracle.com/licenses/universal-foss-exception.

Election of GPLv2

   For the avoidance of doubt, except that if any license choice other
   than GPL or LGPL is available it will apply instead, Oracle elects to
   use only the General Public License version 2 (GPLv2) at this time for
   any software where a choice of GPL license versions is made available
   with the language indicating that GPLv2 or any later version may be
   used, or where a choice of which version of the GPL is applied is
   otherwise unspecified.

GNU General Public License Version 2.0, June 1991

The following applies to all products licensed under the GNU General
Public License, Version 2.0: You may not use the identified files
except in compliance with the GNU General Public License, Version
2.0 (the "License.") You may obtain a copy of the License at
http://www.gnu.org/licenses/gpl-2.0.txt. A copy of the license is
also reproduced below. Unless required by applicable law or agreed
to in writing, software distributed under the License is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language
governing permissions and limitations under the License.


  ======================================================================
  ======================================================================


GNU GENERAL PUBLIC LICENSE
Version 2, June 1991

Copyright (C) 1989, 1991 Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
Everyone is permitted to copy and distribute verbatim
copies of this license document, but changing it is not
allowed.

                     Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software,
and (2) offer you this license which gives you legal permission to
copy, distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on,
we want its recipients to know that what they have is not the original,
so that any problems introduced by others will not reflect on the
original authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

  2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) You must cause the modified files to carry prominent notices
    stating that you changed the files and the date of any change.

    b) You must cause any work that you distribute or publish, that in
    whole or in part contains or is derived from the Program or any
    part thereof, to be licensed as a whole at no charge to all third
    parties under the terms of this License.

    c) If the modified program normally reads commands interactively
    when run, you must cause it, when started running for such
    interactive use in the most ordinary way, to print or display an
    announcement including an appropriate copyright notice and a
    notice that there is no warranty (or else, saying that you provide
    a warranty) and that users may redistribute the program under
    these conditions, and telling the user how to view a copy of this
    License.  (Exception: if the Program itself is interactive but
    does not normally print such an announcement, your work based on
    the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

    a) Accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of Sections
    1 and 2 above on a medium customarily used for software
    interchange; or,

    b) Accompany it with a written offer, valid for at least three
    years, to give any third party, for a charge no more than your
    cost of physically performing source distribution, a complete
    machine-readable copy of the corresponding source code, to be
    distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange; or,

    c) Accompany it with the information you received as to the offer
    to distribute corresponding source code.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form with such
    an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as
a special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

  4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

  5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

  7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

  9. The Free Software Foundation may publish revised and/or new
versions of the General Public License from time to time.  Such new
versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and
"any later version", you have the option of following the terms and
conditions either of that version or of any later version published by
the Free Software Foundation.  If the Program does not specify a
version number of this License, you may choose any version ever
published by the Free Software Foundation.

  10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the
author to ask for permission.  For software which is copyrighted by the
Free Software Foundation, write to the Free Software Foundation; we
sometimes make exceptions for this.  Our decision will be guided by the
two goals of preserving the free status of all derivatives of our free
software and of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO
WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS
WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN
WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
AND/OR REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU
FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

                     END OF TERMS AND CONDITIONS

   ======================================================================
   ======================================================================

The Universal FOSS Exception, Version 1.0

   In addition to the rights set forth in the other license(s) included in
   the distribution for this software, data, and/or documentation
   (collectively the "Software", and such licenses collectively with this
   additional permission the "Software License"), the copyright holders
   wish to facilitate interoperability with other software, data, and/or
   documentation distributed with complete corresponding source under a
   license that is OSI-approved and/or categorized by the FSF as free
   (collectively "Other FOSS"). We therefore hereby grant the following
   additional permission with respect to the use and distribution of the
   Software with Other FOSS, and the constants, function signatures, data
   structures and other invocation methods used to run or interact with
   each of them (as to each, such software's "Interfaces"):

    i. The Software's Interfaces may, to the extent permitted by the
       license of the Other FOSS, be copied into, used and distributed in
       the Other FOSS in order to enable interoperability, without
       requiring a change to the license of the Other FOSS other than as
       to any Interfaces of the Software embedded therein. The Software's
       Interfaces remain at all times under the Software License,
       including without limitation as used in the Other FOSS (which upon
       any such use also then contains a portion of the Software under the
       Software License).

   ii. The Other FOSS's Interfaces may, to the extent permitted by the
       license of the Other FOSS, be copied into, used and distributed in
       the Software in order to enable interoperability, without requiring
       that such Interfaces be licensed under the terms of the Software
       License or otherwise altering their original terms, if this does
       not require any portion of the Software other than such Interfaces
       to be licensed under the terms other than the Software License.

   iii. If only Interfaces and no other code is copied between the
       Software and the Other FOSS in either direction, the use and/or
       distribution of the Software with the Other FOSS shall not be
       deemed to require that the Other FOSS be licensed under the license
       of the Software, other than as to any Interfaces of the Software
       copied into the Other FOSS. This includes, by way of example and
       without limitation, statically or dynamically linking the Software
       together with Other FOSS after enabling interoperability using the
       Interfaces of one or both, and distributing the resulting
       combination under different licenses for the respective portions
       thereof.

       For avoidance of doubt, a license which is OSI-approved or
       categorized by the FSF as free, includes, for the purpose of this
       permission, such licenses with additional permissions, and any
       license that has previously been so approved or categorized as
       free, even if now deprecated or otherwise no longer recognized as
       approved or free. Nothing in this additional permission grants any
       right to distribute any portion of the Software on terms other than
       those of the Software License or grants any additional permission
       of any kind for use or distribution of the Software in conjunction
       with software other than Other FOSS.

   ======================================================================
   ======================================================================

Licenses for Third-Party Components

   MySQL 8.4.8 Community bundles the following third-party components under
   their own licenses. The full per-component license texts are installed on
   the head node at /usr/share/doc/mysql-community-libs/LICENSE. In summary:

   Permissively-licensed (BSD-style / MIT): Boost C++ Libraries, cURL
   (libcurl), Cyrus SASL, dtoa.c (Lucent), Editline Library (libedit),
   Facebook Fast Checksum Patch / Facebook Patches, FMT, Fred Fish's Dbug
   Library (public domain), Google Controlling Master Thread I/O Rate Patch,
   Google Perftools (TCMalloc), Google Protocol Buffers, Google SMP Patch,
   Google Test (GMock), gperftools, double-conversion, jemalloc, LZ4, MeCab,
   MeCab Dictionary, memcached, nt_servc (public domain), Percona Multiple
   I/O Threads Patch, RapidJSON, Richard A. O'Keefe String Library,
   Time Zone Database (public domain), unordered_dense, xxHash, zlib.

   Apache-2.0: abseil-cpp (embedded in Google Protocol Buffers), OpenSSL 3.0.

   Dual BSD / GPLv2 (Oracle elects BSD): ZSTD (Zstandard).

   LGPL-2.1: Libaio.

   GPL-2.0 / Perl Artistic 1.0 (Oracle elects Artistic 1.0): Memcached.pm.

   CC-BY-SA 3.0 (documentation portion only): Kerberos5 documentation.

   Other mixed-permissive: Kerberos5 (MIT + contributor licenses), ICU4C
   Unicode Libraries (Unicode + ICU + cjdict/laodict/burmesedict BSD terms,
   Time Zone Database public domain, NAIST licenses for dictionary data),
   EPSG Geodetic Parameter Dataset (IOGP terms of use), libevent (3-clause
   BSD + OpenBSD + MIT arc4/libutp sub-components), LibFIDO + libcbor (BSD +
   MIT), libtirpc (BSD-3-Clause style). Unicode Data Files & Software: see
   Unicode Inc. License Agreement.

   The full verbatim text of each third-party license is included on the
   distribution at /usr/share/doc/mysql-community-libs/LICENSE and is
   available from Oracle's Written Offer for Source Code (see
   http://www.oracle.com/goto/opensourcecode) or by written request to
   Oracle America, Inc., Attn: Senior Vice President, Development and
   Engineering Legal, 500 Oracle Parkway, 10th Floor, Redwood Shores, CA
   94065. A full copy may also be obtained from within the MySQL 8.4.8
   source tarball referenced in this block's source-code pointer above.

Standard Licenses incorporated by reference:

   * GNU Lesser General Public License v2.1, February 1999 — see
     http://www.gnu.org/licenses/lgpl-2.1.html
   * Perl "Artistic License" 1.0 — see https://dev.perl.org/licenses/artistic.html
   * Apache License Version 2.0, January 2004 — see http://www.apache.org/licenses/LICENSE-2.0
```

---

## Intel MPI; version 2021.17 (2021.17.2.94)

<https://www.intel.com/content/www/us/en/developer/articles/tool/oneapi-standalone-components.html#mpi>

```text
Intel(R) MPI Library: Copyright (C) 2009 Intel Corporation

    * Package Intel MPI's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/impi/l_mpi_oneapi_p_2021.17.2.94_offline.sh

Intel Simplified Software License (Version October 2022)

Use and Redistribution. You may use and redistribute the software, which is
provided in binary form only, (the "Software"), without modification, provided the
following conditions are met:

* Redistributions must reproduce the above copyright notice and these terms of use
in the Software and in the documentation and/or other materials provided with
the distribution.
* Neither the name of Intel nor the names of its suppliers may be used to endorse
or promote products derived from this Software without specific prior written
permission.
* No reverse engineering, decompilation, or disassembly of the Software is
permitted, nor any modification or alteration of the Software or its operation
at any time, including during execution.

No other licenses. Except as provided in the preceding section, Intel grants no
licenses or other rights by implication, estoppel or otherwise to, patent,
copyright, trademark, trade name, service mark or other intellectual property
licenses or rights of Intel.

Third party software. "Third Party Software" means the files (if any) listed in
the "third-party-software.txt" or other similarly-named text file that may be
included with the Software. Third Party Software, even if included with the
distribution of the Software, may be governed by separate license terms, including
without limitation, third party license terms, open source software notices and
terms, and/or other Intel software license terms. These separate license terms
solely govern Your use of the Third Party Software.

DISCLAIMER. THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT ARE
DISCLAIMED. THIS SOFTWARE IS NOT INTENDED FOR USE IN SYSTEMS OR APPLICATIONS
WHERE FAILURE OF THE SOFTWARE MAY CAUSE PERSONAL INJURY OR DEATH AND YOU AGREE
THAT YOU ARE FULLY RESPONSIBLE FOR ANY CLAIMS, COSTS, DAMAGES, EXPENSES, AND
ATTORNEYS' FEES ARISING OUT OF ANY SUCH USE, EVEN IF ANY CLAIM ALLEGES THAT
INTEL WAS NEGLIGENT REGARDING THE DESIGN OR MANUFACTURE OF THE SOFTWARE.

LIMITATION OF LIABILITY. IN NO EVENT WILL INTEL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

No support. Intel may make changes to the Software, at any time without notice,
and is not obligated to support, update or provide training for the Software.

Termination. Your right to use the Software is terminated in the event of your
breach of this license.

Feedback. Should you provide Intel with comments, modifications, corrections,
enhancements or other input ("Feedback") related to the Software, Intel will be
free to use, disclose, reproduce, license or otherwise distribute or exploit the
Feedback in its sole discretion without any obligations or restrictions of any
kind, including without limitation, intellectual property rights or licensing
obligations.

Compliance with laws. You agree to comply with all relevant laws and regulations
governing your use, transfer, import or export (or prohibition thereof) of the
Software.

Governing law.  All disputes will be governed by the laws of the United States of
America and the State of Delaware without reference to conflict of law principles
and subject to the exclusive jurisdiction of the state or federal courts sitting
in the State of Delaware, and each party agrees that it submits to the personal
jurisdiction and venue of those courts and waives any objections. THE UNITED
NATIONS CONVENTION ON CONTRACTS FOR THE INTERNATIONAL SALE OF GOODS (1980) IS
SPECIFICALLY EXCLUDED AND WILL NOT APPLY TO THE SOFTWARE.
```

---

## setuptools; version 80.10.1

<https://pypi.org/project/setuptools>

```text
Copyright Jason R. Coombs

    * Package setuptools's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Copyright Jason R. Coombs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
```

---

## jsonschema; version 4.26.0

<https://github.com/python-jsonschema/jsonschema>

```text
Copyright (c) 2013 Julian Berman

    * Package jsonschema's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

MIT License

Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

---

## efs-utils; version 2.4.0

<https://github.com/aws/efs-utils>

```text
Copyright 2017 Amazon.com, Inc. or its affiliates.

    * Package efs-utils's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/efs/v2.4.0.tar.gz

MIT License

Copyright 2017 Amazon.com, Inc. or its affiliates.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## tabulate; version 0.8.10

<https://pypi.org/project/tabulate>

```text
Copyright (c) 2011-2020 Sergey Astanin and contributors

    * Package tabulate's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Copyright (c) 2011-2020 Sergey Astanin and contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

---

## gdrcopy; version 2.5.2

<https://github.com/NVIDIA/gdrcopy/releases/tag/v2.5.2>

```text
Copyright (c) 2014-2021, NVIDIA CORPORATION. All rights reserved.

    * Package gdrcopy's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/gdr_copy/v2.5.2.tar.gz

Copyright (c) 2014-2021, NVIDIA CORPORATION. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

---

## pyyaml; version 6.0.3

<https://pypi.org/project/PyYAML/>

```text
Copyright (c) 2017-2021 Ingy döt Net
Copyright (c) 2006-2016 Kirill Simonov
```

## chevron; version 0.14.0

<https://pypi.org/project/chevron/>

```text
Copyright (c) 2014 Noah Morrison

    * Package chevron's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

    * Package pyyaml's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/PyPi/pypi-
dependencies-3.12-x86_64.tgz

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## libjwt; version 1.18.4 (1.17.0 on AL2)

<https://github.com/benmcollins/libjwt>

```text
Copyright (C) 2015-2022 Ben Collins <bcollins@maclara-llc.com>

    * Package libjwt's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/jwt/v1.18.4.tar.gz
      (AL2 continues to use https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/jwt/v1.17.0.tar.gz)

Mozilla Public License Version 2.0
==================================

1. Definitions
--------------

1.1. "Contributor"
    means each individual or legal entity that creates, contributes to
    the creation of, or owns Covered Software.

1.2. "Contributor Version"
    means the combination of the Contributions of others (if any) used
    by a Contributor and that particular Contributor's Contribution.

1.3. "Contribution"
    means Covered Software of a particular Contributor.

1.4. "Covered Software"
    means Source Code Form to which the initial Contributor has attached
    the notice in Exhibit A, the Executable Form of such Source Code
    Form, and Modifications of such Source Code Form, in each case
    including portions thereof.

1.5. "Incompatible With Secondary Licenses"
    means

    (a) that the initial Contributor has attached the notice described
        in Exhibit B to the Covered Software; or

    (b) that the Covered Software was made available under the terms of
        version 1.1 or earlier of the License, but not also under the
        terms of a Secondary License.

1.6. "Executable Form"
    means any form of the work other than Source Code Form.

1.7. "Larger Work"
    means a work that combines Covered Software with other material, in
    a separate file or files, that is not Covered Software.

1.8. "License"
    means this document.

1.9. "Licensable"
    means having the right to grant, to the maximum extent possible,
    whether at the time of the initial grant or subsequently, any and
    all of the rights conveyed by this License.

1.10. "Modifications"
    means any of the following:

    (a) any file in Source Code Form that results from an addition to,
        deletion from, or modification of the contents of Covered
        Software; or

    (b) any new file in Source Code Form that contains any Covered
        Software.

1.11. "Patent Claims" of a Contributor
    means any patent claim(s), including without limitation, method,
    process, and apparatus claims, in any patent Licensable by such
    Contributor that would be infringed, but for the grant of the
    License, by the making, using, selling, offering for sale, having
    made, import, or transfer of either its Contributions or its
    Contributor Version.

1.12. "Secondary License"
    means either the GNU General Public License, Version 2.0, the GNU
    Lesser General Public License, Version 2.1, the GNU Affero General
    Public License, Version 3.0, or any later versions of those
    licenses.

1.13. "Source Code Form"
    means the form of the work preferred for making modifications.

1.14. "You" (or "Your")
    means an individual or a legal entity exercising rights under this
    License. For legal entities, "You" includes any entity that
    controls, is controlled by, or is under common control with You. For
    purposes of this definition, "control" means (a) the power, direct
    or indirect, to cause the direction or management of such entity,
    whether by contract or otherwise, or (b) ownership of more than
    fifty percent (50%) of the outstanding shares or beneficial
    ownership of such entity.

2. License Grants and Conditions
--------------------------------

2.1. Grants

Each Contributor hereby grants You a world-wide, royalty-free,
non-exclusive license:

(a) under intellectual property rights (other than patent or trademark)
    Licensable by such Contributor to use, reproduce, make available,
    modify, display, perform, distribute, and otherwise exploit its
    Contributions, either on an unmodified basis, with Modifications, or
    as part of a Larger Work; and

(b) under Patent Claims of such Contributor to make, use, sell, offer
    for sale, have made, import, and otherwise transfer either its
    Contributions or its Contributor Version.

2.2. Effective Date

The licenses granted in Section 2.1 with respect to any Contribution
become effective for each Contribution on the date the Contributor first
distributes such Contribution.

2.3. Limitations on Grant Scope

The licenses granted in this Section 2 are the only rights granted under
this License. No additional rights or licenses will be implied from the
distribution or licensing of Covered Software under this License.
Notwithstanding Section 2.1(b) above, no patent license is granted by a
Contributor:

(a) for any code that a Contributor has removed from Covered Software;
    or

(b) for infringements caused by: (i) Your and any other third party's
    modifications of Covered Software, or (ii) the combination of its
    Contributions with other software (except as part of its Contributor
    Version); or

(c) under Patent Claims infringed by Covered Software in the absence of
    its Contributions.

This License does not grant any rights in the trademarks, service marks,
or logos of any Contributor (except as may be necessary to comply with
the notice requirements in Section 3.4).

2.4. Subsequent Licenses

No Contributor makes additional grants as a result of Your choice to
distribute the Covered Software under a subsequent version of this
License (see Section 10.2) or under the terms of a Secondary License (if
permitted under the terms of Section 3.3).

2.5. Representation

Each Contributor represents that the Contributor believes its
Contributions are its original creation(s) or it has sufficient rights
to grant the rights to its Contributions conveyed by this License.

2.6. Fair Use

This License is not intended to limit any rights You have under
applicable copyright doctrines of fair use, fair dealing, or other
equivalents.

2.7. Conditions

Sections 3.1, 3.2, 3.3, and 3.4 are conditions of the licenses granted
in Section 2.1.

3. Responsibilities
-------------------

3.1. Distribution of Source Form

All distribution of Covered Software in Source Code Form, including any
Modifications that You create or to which You contribute, must be under
the terms of this License. You must inform recipients that the Source
Code Form of the Covered Software is governed by the terms of this
License, and how they can obtain a copy of this License. You may not
attempt to alter or restrict the recipients' rights in the Source Code
Form.

3.2. Distribution of Executable Form

If You distribute Covered Software in Executable Form then:

(a) such Covered Software must also be made available in Source Code
    Form, as described in Section 3.1, and You must inform recipients of
    the Executable Form how they can obtain a copy of such Source Code
    Form by reasonable means in a timely manner, at a charge no more
    than the cost of distribution to the recipient; and

(b) You may distribute such Executable Form under the terms of this
    License, or sublicense it under different terms, provided that the
    license for the Executable Form does not attempt to limit or alter
    the recipients' rights in the Source Code Form under this License.

3.3. Distribution of a Larger Work

You may create and distribute a Larger Work under terms of Your choice,
provided that You also comply with the requirements of this License for
the Covered Software. If the Larger Work is a combination of Covered
Software with a work governed by one or more Secondary Licenses, and the
Covered Software is not Incompatible With Secondary Licenses, this
License permits You to additionally distribute such Covered Software
under the terms of such Secondary License(s), so that the recipient of
the Larger Work may, at their option, further distribute the Covered
Software under the terms of either this License or such Secondary
License(s).

3.4. Notices

You may not remove or alter the substance of any license notices
(including copyright notices, patent notices, disclaimers of warranty,
or limitations of liability) contained within the Source Code Form of
the Covered Software, except that You may alter any license notices to
the extent required to remedy known factual inaccuracies.

3.5. Application of Additional Terms

You may choose to offer, and to charge a fee for, warranty, support,
indemnity or liability obligations to one or more recipients of Covered
Software. However, You may do so only on Your own behalf, and not on
behalf of any Contributor. You must make it absolutely clear that any
such warranty, support, indemnity, or liability obligation is offered by
You alone, and You hereby agree to indemnify every Contributor for any
liability incurred by such Contributor as a result of warranty, support,
indemnity or liability terms You offer. You may include additional
disclaimers of warranty and limitations of liability specific to any
jurisdiction.

4. Inability to Comply Due to Statute or Regulation
---------------------------------------------------

If it is impossible for You to comply with any of the terms of this
License with respect to some or all of the Covered Software due to
statute, judicial order, or regulation then You must: (a) comply with
the terms of this License to the maximum extent possible; and (b)
describe the limitations and the code they affect. Such description must
be placed in a text file included with all distributions of the Covered
Software under this License. Except to the extent prohibited by statute
or regulation, such description must be sufficiently detailed for a
recipient of ordinary skill to be able to understand it.

5. Termination
--------------

5.1. The rights granted under this License will terminate automatically
if You fail to comply with any of its terms. However, if You become
compliant, then the rights granted under this License from a particular
Contributor are reinstated (a) provisionally, unless and until such
Contributor explicitly and finally terminates Your grants, and (b) on an
ongoing basis, if such Contributor fails to notify You of the
non-compliance by some reasonable means prior to 60 days after You have
come back into compliance. Moreover, Your grants from a particular
Contributor are reinstated on an ongoing basis if such Contributor
notifies You of the non-compliance by some reasonable means, this is the
first time You have received notice of non-compliance with this License
from such Contributor, and You become compliant prior to 30 days after
Your receipt of the notice.

5.2. If You initiate litigation against any entity by asserting a patent
infringement claim (excluding declaratory judgment actions,
counter-claims, and cross-claims) alleging that a Contributor Version
directly or indirectly infringes any patent, then the rights granted to
You by any and all Contributors for the Covered Software under Section
2.1 of this License shall terminate.

5.3. In the event of termination under Sections 5.1 or 5.2 above, all
end user license agreements (excluding distributors and resellers) which
have been validly granted by You or Your distributors under this License
prior to termination shall survive termination.

************************************************************************
*                                                                      *
*  6. Disclaimer of Warranty                                           *
*  -------------------------                                           *
*                                                                      *
*  Covered Software is provided under this License on an "as is"       *
*  basis, without warranty of any kind, either expressed, implied, or  *
*  statutory, including, without limitation, warranties that the       *
*  Covered Software is free of defects, merchantable, fit for a        *
*  particular purpose or non-infringing. The entire risk as to the     *
*  quality and performance of the Covered Software is with You.        *
*  Should any Covered Software prove defective in any respect, You     *
*  (not any Contributor) assume the cost of any necessary servicing,   *
*  repair, or correction. This disclaimer of warranty constitutes an   *
*  essential part of this License. No use of any Covered Software is   *
*  authorized under this License except under this disclaimer.         *
*                                                                      *
************************************************************************

************************************************************************
*                                                                      *
*  7. Limitation of Liability                                          *
*  --------------------------                                          *
*                                                                      *
*  Under no circumstances and under no legal theory, whether tort      *
*  (including negligence), contract, or otherwise, shall any           *
*  Contributor, or anyone who distributes Covered Software as          *
*  permitted above, be liable to You for any direct, indirect,         *
*  special, incidental, or consequential damages of any character      *
*  including, without limitation, damages for lost profits, loss of    *
*  goodwill, work stoppage, computer failure or malfunction, or any    *
*  and all other commercial damages or losses, even if such party      *
*  shall have been informed of the possibility of such damages. This   *
*  limitation of liability shall not apply to liability for death or   *
*  personal injury resulting from such party's negligence to the       *
*  extent applicable law prohibits such limitation. Some               *
*  jurisdictions do not allow the exclusion or limitation of           *
*  incidental or consequential damages, so this exclusion and          *
*  limitation may not apply to You.                                    *
*                                                                      *
************************************************************************

8. Litigation
-------------

Any litigation relating to this License may be brought only in the
courts of a jurisdiction where the defendant maintains its principal
place of business and such litigation shall be governed by laws of that
jurisdiction, without reference to its conflict-of-law provisions.
Nothing in this Section shall prevent a party's ability to bring
cross-claims or counter-claims.

9. Miscellaneous
----------------

This License represents the complete agreement concerning the subject
matter hereof. If any provision of this License is held to be
unenforceable, such provision shall be reformed only to the extent
necessary to make it enforceable. Any law or regulation which provides
that the language of a contract shall be construed against the drafter
shall not be used to construe this License against a Contributor.

10. Versions of the License
---------------------------

10.1. New Versions

Mozilla Foundation is the license steward. Except as provided in Section
10.3, no one other than the license steward has the right to modify or
publish new versions of this License. Each version will be given a
distinguishing version number.

10.2. Effect of New Versions

You may distribute the Covered Software under the terms of the version
of the License under which You originally received the Covered Software,
or under the terms of any subsequent version published by the license
steward.

10.3. Modified Versions

If you create software not governed by this License, and you want to
create a new license for such software, you may create and use a
modified version of this License if you rename the license and remove
any references to the name of the license steward (except to note that
such modified license differs from this License).

10.4. Distributing Source Code Form that is Incompatible With Secondary
Licenses

If You choose to distribute Source Code Form that is Incompatible With
Secondary Licenses under the terms of this version of the License, the
notice described in Exhibit B of this License must be attached.

Exhibit A - Source Code Form License Notice
-------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

If it is not possible or desirable to put the notice in a particular
file, then You may include the notice in a location (such as a LICENSE
file in a relevant directory) where a recipient would be likely to look
for such a notice.

You may add additional accurate notices of copyright ownership.

Exhibit B - "Incompatible With Secondary Licenses" Notice
---------------------------------------------------------

  This Source Code Form is "Incompatible With Secondary Licenses", asP
  defined by the Mozilla Public License, v. 2.0.
```

---

## Amazon DCV; version 2025.0-20103

<https://www.nice-dcv.com/>

```text
© 2020-2025, NICE s.r.l. or its affiliates. All rights reserved.

    * Package Amazon DCV's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/dcv/nice-
dcv-2025.0-20103-el8-x86_64.tgz

END-USER LICENSE AGREEMENT (EULA)
for NICE Software and Solutions
(Version 8.5)

This End User License Agreement ("EULA" or "Agreement") contains the terms and conditions that
govern your ("Licensee" or "you" or "your") access to and use of NICE EnginFrame and Amazon DCV
(together with any updates, including updates to the software name, or enhancements, and
accompanying documentation, "Software") and Amazon DCV Web Client software development kit
(together with any updates, including any updates to the software development kit name, or
enhancements, and accompanying documentation,"SDK"). As used in this EULA, "NICE" means
NICE, S.r.l. with principal offices located at Via Milliavacca, 9 – 14100 Asti - Italy ("NICE IT"), except
that if Licensee is located in the United States, "NICE" means NICE USA LLC, with principal offices
at 410 Terry Avenue North, Seattle, Washington, 98109-5210 ("NICE US"). This EULA supplements
the AWS Customer Agreement posted at aws.amazon.com/agreement or other agreement with
NICE or an affiliate governing your use of NICE services (the "Customer Agreement"), and unless
otherwise defined in this EULA, capitalized terms will have the same meaning as set forth in the
Customer Agreement.

1. LICENSE TO AND USE OF THE SOFTWARE. The Software may be accessed and used only in
accordance with this EULA and the Customer Agreement, and subject to these terms:
(a) You are granted a limited, non-transferable, revocable, non-sublicensable license to install and
use the Software for your internal business purposes only and only in the quantity that you have
purchased from NICE or an authorized reseller of the Software, or to the extent your use has
otherwise been authorized by NICE or Amazon Web Services.
(b) if you requested access to the Software to evaluate its features and functionality, you are
granted a limited, non-transferable, revocable, non-sublicensable license to install and use the
Software for your internal evaluation and testing purposes only, and only in the quantity that you
have requested from NICE.
(c) The source code for the Amazon DCV Access Console Web Client, Amazon DCV Access
Console Handler, Amazon DCV Access Console Authentication Server, Amazon DCV Access
Console Configuration Wizard, Amazon DCV Access Console Model, and Amazon DCV Access
Console Integration Tests (“Open-Sourced Amazon DCV Access Console Components”) is
governed by the Apache 2.0 License (https://github.com/aws/dcv-access-console/blob/main/LICENSE),
not this EULA or the Customer Agreement. Your access to and use of the code is subject to the terms
of the Apache 2.0 License. Notwithstanding the foregoing, your use of Amazon DCV
(including any Amazon DCV product or component available for download at https://www.amazondcv.com/
and any successor or related site designated by NICE) is always subject to the terms of this EULA
and the Customer Agreement even when they are used in combination with the Open-Sourced
Amazon DCV Access Console Components, or any derivative works created using the Open-Sourced
Amazon DCV Access Console Components.

2. BETA PARTICIPATION. NICE may provide Licensee certain features, technologies, software, and
services that are not yet generally available, including those labeled "beta", "preview", "pre-release",
or "experimental" (each, a "Beta"). Access and use of Betas are subject to any Beta terms provided
by NICE and if there is a conflict between the terms of this Section and any Beta terms, Beta terms
will take precedence. Betas are Software subject to all the terms and conditions of this EULA.
(a) Licensee agrees not to allow access to or use of any Beta or any related materials by any third
party other than Licensee's employees and contractors who have a need to use or access in
connection with Licensee's internal evaluation activities and have executed written non-disclosure
agreements obligating them to protect the confidentiality of the Beta and related materials.
(b) Licensee must comply with all policies and guidelines related to any Beta as posted on the
NICE's website or otherwise made available to Licensee. NICE may add or modify restrictions,
including usage limits related to access to or use of any Beta or related materials at any time. If
requested by NICE, Licensee will promptly increase or decrease usage to the levels that NICE may
specify. Any service level agreements that Licensee may have for the Software do not apply to
Betas.
(c) Licensee will, when requested by NICE, provide NICE with information relating to Licensee's
access, use, testing, and evaluation of the Beta and any related Beta Materials, including
observations or information regarding the performance, features, and functionality of the Beta in
the form reasonably requested by NICE ("Test Observations"). NICE will own and may use and
evaluate all Test Observations for its own purposes. All Betas, related materials, and Test
Observations are NICE Confidential Information. Each individual Beta license will automatically
terminate upon the release of a generally available version of the Beta or upon notice of termination
by NICE which may occur at any time and for any reason. Upon the termination of Licensee's
license to any Beta, Licensee will cease use of the Beta and immediately return or, if instructed by
NICE, destroy all copies of the Beta and all related materials. NICE does not guarantee that any
Beta will ever be made generally available or that any generally available version will contain the
same or similar functionality as any Beta version made available to Licensee.
(d) WITHOUT LIMITING ANY DISCLAIMERS HEREIN, BETAS ARE NOT READY FOR GENERAL
COMMERCIAL RELEASE AND MAY CONTAIN BUGS, ERRORS, DEFECTS OR HARMFUL
COMPONENTS. ACCORDINGLY, AND NOTWITHSTANDING ANYTHING TO THE CONTRARY IN THIS
EULA OR OTHERWISE, NICE PROVIDES BETAS TO LICENSEE "AS IS."

3. USE RESTRICTIONS. Your use of the Software is conditioned upon your compliance with the
following limitations:
(a) Licensee will not distribute, rent, lease, lend, loan, transfer, assign, resell, sublicense, disclose,
or otherwise provide the Software to or use the Software for the benefit of any third party (including
acting as a service bureau or provider of a time sharing service). Notwithstanding the foregoing,
Licensee may permit its third party contractors to use the software for Licensee's internal business
purposes provided that Licensee enters to a binding agreement with contractor requiring contractor
to comply with this EULA and is solely responsible and liable for any breach of this EULA including
any unauthorized use of the Software by Licensee's contractors.
(b) Licensee will not modify, adapt, translate, alter, tamper with, repair, or otherwise create
derivative works of the Software, subject to Section 10.
(c) Licensee will not decompile, decipher, disassemble, reverse engineer or otherwise attempt to
access or derive source code of the Software, except to the extent applicable law does not allow
this restriction. (d) Licensee will not attempt to use the Software in excess of any usage limits and
will not attempt to circumvent any technology in or with the Software that is designed to monitor,
restrict, or limit use. Licensee acknowledges and agrees that the Software (including all evaluation
versions) may require the use of license key or token in order to operate and that operation of the
Software will automatically terminate upon expiration.
(e) Licensee will not remove any proprietary notices or labels on the Software or any copy thereof.
(f) Licensee requires that each end user before accessing the Software, agrees to comply with this
EULA. (g) Licensee will not make any use of the Software in any manner not expressly permitted by
this EULA.

4. INTELLECTUAL PROPERTY.
(a) The Software and SDK (including the related documentation) are owned by NICE. Licensee
acknowledges and agrees that title to the Software and SDK, including the documentation, and all
the copies thereof, including all industrial and intellectual property rights (including the exclusive
rights of economic exploitation), copyright, trade secrets, and patent rights, remains with NICE.
(b) Licensee has no obligation to give NICE any suggestions, comments, or other feedback relating
to the Software ("Feedback"). To the extent Licensee provides Feedback to NICE, NICE may use and
exercise any and all rights in the Feedback without obligation or restriction of any kind during and
after the Term, and Feedback will not be deemed to be confidential information of Licensee or
otherwise create any confidentiality obligation. Licensee agrees not to provide any Feedback that:
(i) Licensee knows is subject to any patent, copyright or other intellectual property claim or right of
any third party; or (ii) is subject to license terms which seek to require any products incorporating or
derived from the Feedback, or other NICE intellectual property, to be licensed to or otherwise
shared with any third party.

5. AUDIT. Licensee shall maintain accurate records regarding Licensee's use of the Software and
compliance with this EULA and, upon request, make such records available to NICE and certify
Licensee's compliance with this EULA. NICE or a third party may examine and audit Licensee's
access, use, and deployment of the Software and verify Licensee's compliance with this EULA. Any
audit will take place during normal business hours on at least 10 days prior written notice. If
Licensee misreported any figure or underpaid any amount, Licensee will remit to NICE the amount
of any underpayment within 10 days after notification of the discrepancy. If the discrepancy
exceeds $1,000 U.S. dollars or 5% of the total amount purchased or reported by Licensee for the
period audited, then Licensee will reimburse NICE for the reasonable costs of the audit.

6. SUPPORT SERVICES. Licensee may be eligible to subscribe to software support for any or all of
the Software (the "Support Services", as described and regulated under the Standard Support
Services for NICE Products terms, available here:
https://www.nice-software.com/html/pdf/NICE_Standard_Support_Services.pdf , as may be
updated). Support Services are subject to and governed by the terms of this EULA and the
Customer Agreement, as is any update or upgrade to the Software provided by NICE in connection
with Support Services. If the Support Services are terminated, Licensee's license to the Software
under this EULA will continue in accordance with the terms of this EULA. If Support Services expire
or terminate and Licensee later reinstates Support Services, Licensee shall pay a reinstatement fee
equal to 70% of the current annual charge for Support Services for the period of time when
Licensee did not receive Support Services. The reinstatement fee for any partial year will be a pro
rata portion of the applicable annual fee.

7. LIMITED WARRANTY.
(a) NICE warrants that the Software will for a period of 60 days from delivery to the Licensee (the
"Warranty Period"), when used in accordance with NICE's written instructions, operate
substantially in compliance with NICE's official published documentation. NICE's sole
responsibility, and Licensee's exclusive remedy, in the event of breach of the limited warranty
during the Warranty Period, is for NICE, at its option, to use reasonable efforts to repair the
Software, replace the Software, or provide a refund. NICE shall not be responsible or liable for any
noncompliance with the foregoing warranty or limitations or defects of the Software, if they have
been caused, in whole or in part, by unauthorized behavior of Licensee, any use of the Software
which is inconsistent with the Documentation, any accident, abuse, or misapplication, and/or if
they arise from or are related to software or any other products which are not supplied by NICE.
(b) DISCLAIMER. EXCEPT FOR THE LIMITED WARRANTY IN SECTION 7(A), THE SOFTWARE IS
PROVIDED "AS IS." EXCEPT TO THE EXTENT PROHIBITED BY LAW, OR TO THE EXTENT ANY
STATUTORY RIGHTS APPLY THAT CANNOT BE EXCLUDED, LIMITED OR WAIVED, NICE AND ITS
AFFILIATES AND LICENSORS (I) MAKE NO OTHER REPRESENTATIONS OR WARRANTIES OF ANY
KIND, WHETHER EXPRESS, IMPLIED, STATUTORY OR OTHERWISE REGARDING THE SOFTWARE,
AND (II) DISCLAIM ALL OTHER WARRANTIES, INCLUDING ANY IMPLIED OR EXPRESS WARRANTIES
(A) OF MERCHANTABILITY, SATISFACTORY QUALITY, FITNESS FOR A PARTICULAR PURPOSE, NON-
INFRINGEMENT, OR QUIET ENJOYMENT, (B) ARISING OUT OF ANY COURSE OF DEALING OR
USAGE OF TRADE, (C) THAT THE SOFTWARE WILL BE UNINTERRUPTED, ERROR FREE, OR FREE OF
HARMFUL COMPONENTS, AND (D) THAT ANY CONTENT WILL BE SECURE OR NOT OTHERWISE
LOST OR ALTERED.

8. LIMITATIONS OF LIABILITY. NICE AND ITS AFFILIATES AND LICENSORS WILL NOT BE LIABLE TO
LICENSEE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR EXEMPLARY
DAMAGES (INCLUDING DAMAGES FOR LOSS OF PROFITS, REVENUES, CUSTOMERS,
OPPORTUNITIES, GOODWILL, USE, OR DATA), EVEN IF A PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES. FURTHER, NEITHER NICE NOR ANY OF ITS AFFILIATES OR
LICENSORS WILL BE RESPONSIBLE FOR ANY COMPENSATION, REIMBURSEMENT, OR DAMAGES
ARISING IN CONNECTION WITH: (A) YOUR INABILITY TO USE THE SOFTWARE, INCLUDING AS A
RESULT OF ANY (I) TERMINATION OR EXPIRATION OF THIS EULA OR YOUR USE OF OR ACCESS TO
THE SOFTWARE OR, (II) ANY ERROR OR UNANTICIPATED INTERUPTION IN THE OPERATION OF THE
SOFTWARE FOR ANY REASON; (B) THE COST OF PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; (C) ANY INVESTMENTS, EXPENDITURES, OR COMMITMENTS BY LICENSEE IN
CONNECTION WITH THIS EULA OR YOUR USE OF OR ACCESS TO THE SOFTWARE; OR (D) ANY
UNAUTHORIZED ACCESS TO, ALTERATION OF, OR THE DELETION, DESTRUCTION, DAMAGE, LOSS
OR FAILURE TO STORE ANY OF YOUR CONTENT OR OTHER DATA. IN ANY CASE, NICE AND ITS
AFFILIATES' AND LICENSORS' AGGREGATE LIABILITY UNDER THIS EULA WILL NOT EXCEED THE
AMOUNT LICENSEE ACTUALLY PAID NICE FOR THE SOFTWARE THAT GAVE RISE TO THE CLAIM
DURING THE 12 MONTHS BEFORE THE LIABILITY AROSE. THE LIMITATIONS IN THIS SECTION
APPLY ONLY TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW.

9. TERM AND TERMINATION.
(a) This EULA is effective upon the earlier of NICE's (i) acceptance of an order for Software, (ii)
delivery of the Software and it will continue until it expires or terminates ("Term").
(b) NICE may terminate this EULA at any time and for any reason on 30 days' prior written notice to
Licensee. Your rights under this EULA will automatically terminate without notice from us if you fail
to comply with any term of this EULA or the Customer Agreement.
(c) Licensee may terminate this EULA at any time by uninstalling or destroying all copies of the
Software that are in your possession or control.
(d) Upon termination or expiration of this EULA, Licensee shall (i) be no longer entitled to use the
Software and documentation, (ii) immediately remove the Software from all computers on which
the Software is installed, (iii) return to NICE, within 5 days from expiration or termination, all copies
of the Software and documentation (or destroy such materials, as instructed by NICE) and will
certify in writing that all copies or partial copies of the Software and documentation have been
returned to NICE or destroyed; and (iv) remain responsible and liable for all fees and charges for the
Software that Licensee incurred through the date of termination or expiration.
(e) If NICE terminates this EULA for convenience under subsection (b) of this Section, NICE will
issue Licensee a prorata credit of any license fees prepaid by Licensee based a ten year life-span
for the Software.
(f) Sections 3-11 inclusive will survive termination of this EULA.

10. SDK. If you downloaded the SDK, you may use, reproduce, distribute, publish, and sublicense
the SDK, and create derivative works of the SDK and Amazon DCV Web Client solely to the extent
those derivative works implement the Amazon DCV Web Client, subject to the following conditions:
(a) You will not remove any proprietary notices or labels on the SDK or any copy thereof.
(b) You will include this permission notice in all copies or substantial portions of the SDK.
(c) You require that each end user before accessing the SDK, Amazon DCV Web Client, or any
copies, derivative works or substantial portions thereof, agrees to comply with this EULA.
(d) Some components of the SDK may be governed by third party software licenses. Your license
rights with respect to these individual components are defined by the applicable third party
software licenses, and nothing in this Agreement will restrict, limit, or otherwise affect any rights or
obligations you may have, or conditions to which you may be subject, under such third party
software licenses.
(e) THE SDK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SDK OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

11. GENERAL.
(a) Entire Agreement. This EULA and its incorporation of the Customer Agreement, along with
related documents provided by NICE, represents the complete and exclusive agreement between
the parties with respect to the subject matter hereof and supersedes all prior agreements,
negotiations, and understandings. NICE will not be bound by, and specifically objects to, any term,
condition or other provision that is different from or in addition to the provisions of this EULA
(whether or not it would materially alter this EULA) including for example, any term, condition or
other provision (i) submitted by Licensee in any purchase order, receipt, acceptance, confirmation,
correspondence or other document, or (ii) related to any invoicing process that Licensee submits or
require NICE to complete. To the extent there is any conflict between this EULA and the Customer
Agreement, this EULA prevails.
(b) Assignment. Licensee shall not assign or otherwise transfer this EULA or any of Licensee's rights
or obligations, without our prior written consent. Any assignment or transfer in violation of this
Section will be void. NICE may assign this EULA without your consent (i) in connection with a
merger, acquisition or sale of all or substantially all of our assets, or (ii) to any affiliate or as part of a
corporate reorganization; and effective upon such assignment, the assignee is deemed substituted
for NICE as a party to this EULA and NICE is fully released from all of its obligations and duties to
perform under this EULA. Subject to the foregoing, this EULA will be binding upon, and inure to the
benefit of the parties and their respective permitted successors and assigns.
(c) Governing Law and Dispute Resolution for US Licensees. If NICE US is the contracting party to
this EULA, the laws of the State of Washington, without reference to conflict of law rules, govern
this EULA and any dispute of any sort that might arise between NICE and Licensee. The United
Nations Convention for the International Sale of Goods does not apply to this EULA. Any dispute or
claim relating in any way to the Software or this EULA will be adjudicated exclusively in the federal
and state courts located in King County, Washington, and Licensee consents and waives any
objections to such exclusive jurisdiction and venue. Notwithstanding the foregoing, NICE may seek
injunctive (or similar) remedies in any jurisdiction. (d) Governing Law and Dispute Resolution when
Licensees Outside the US. (i) If NICE IT is the contracting party to this EULA, the laws of the
Republic of Italy, without reference to conflict of law rules, govern this EULA and any dispute of any
sort that might arise between NICE and Licensee. The United Nations Convention for the
International Sale of Goods does not apply to this EULA. Any dispute or claim relating in any way to
the Software or this EULA will be adjudicated exclusively in the Court of Milan, Italy, and Licensee
consents and waives any objections to such exclusive jurisdiction and venue. Notwithstanding the
foregoing, NICE may seek injunctive (or similar) remedies in any jurisdiction. (ii) IF NICE IT IS THE
CONTRACTING PARTY, PURSUANT TO AND BY THE EFFECT OF SECTIONS 1341 AND 1342 OF THE
ITALIAN CIVIL CODE, LICENSEE EXPLICITLY APPROVES THE FOLLOWING CONDITIONS: 3 (USE
RESTRICTIONS), 7 (LIMITED WARRANTY), 8 (LIMITATIONS OF LIABILITY), 9 (TERMINATION), 10
(GENERAL - INCLUDING GOVERNING LAW, DISPUTE RESOLUTION, CONFIDENTIALITY AND
PUBLICITY, AND MODIFICATIONS TO THE AGREEMENT).
(e) Waiver. The failure by NICE to enforce any provision of this EULA will not constitute a present or
future waiver of such provision nor will it limit NICE's right to enforce such provision at a later time.
All waivers by NICE must be in writing to be effective.
(f) Severability. If any portion of this Agreement is held to be invalid or unenforceable, the remaining
portions of this Agreement will remain in full force and effect. Any invalid or unenforceable portions
will be interpreted to effectuate the intent of the original portion. If such construction is not
possible, the invalid or unenforceable portion will be severed from this Agreement but the rest of
the Agreement will remain in full force and effect.
(g) Taxes. Each party will be responsible, as required under applicable law, for identifying and
paying all taxes and other governmental fees and charges (and any penalties, interest, and other
additions thereto) that are imposed on that party upon or with respect to the transactions and
payments under this EULA. All fees payable by Licensee are exclusive of applicable taxes and
duties, including VAT, Service Tax, GST, excise taxes, sales and transactions taxes, and gross
receipts tax ("Indirect Taxes"). NICE may charge and Licensee will pay applicable Indirect Taxes that
NICE is legally obligated or authorized to collect from Licensee. Licensee will provide such
information to NICE as reasonably required to determine whether NICE is obligated to collect
Indirect Taxes from Licensee. NICE will not collect, and Licensee will not pay, any Indirect Tax for
which Licensee furnishes NICE a properly completed exemption certificate or a direct payment
permit certificate for which NICE may claim an available exemption from such Indirect Tax. All
payments made by Licensee to NICE under this EULA will be made free and clear of any deduction
or withholding, as may be required by law. If any such deduction or withholding (including cross-
border withholding taxes) is required on any payment, Licensee will pay such additional amounts
as are necessary so that the net amount received by NICE is equal to the amount then due and
payable under this EULA. NICE will provide Licensee with such tax forms as are reasonably
requested in order to reduce or eliminate the amount of any withholding or deduction for taxes in
respect of payments made under this EULA.
(h) Confidentiality And Publicity. Licensee may use NICE Confidential Information only in
connection with Licensee's use of the Software as permitted under this EULA. Licensee will not
disclose NICE Confidential Information during the Term or at any time after without NICE's advance
written consent. Licensee will take all reasonable measures to avoid disclosure, dissemination, or
unauthorized use of NICE Confidential Information, including, at a minimum, those measures
Licensee takes to protect its own confidential information of a similar nature. Licensee will not
issue any press release or make any other public communication with respect to this EULA or your
use of the Software. "NICE Confidential Information" means all nonpublic information disclosed by
NICE its affiliates, business partners or its or their respective employees, contractors or agents that
is designated as confidential or that, given the nature of the information or circumstances
surrounding its disclosure, reasonably should be understood to be confidential. NICE Confidential
Information does not include any information that: (i) is or becomes publicly available without
breach of this EULA; (ii) can be shown by documentation to have been known to Licensee at the
time of receipt from NICE; (iii) is received from a third party who did not acquire or disclose the
same by a wrongful or tortious act; or (iv) can be shown by documentation to have been
independently developed by Licensee without reference to NICE Confidential Information.
(i) Notices. Any notice required or permitted by this EULA to be given to either party shall be
effective upon receipt and shall be given in writing and sent by overnight courier, facsimile, or first
class certified mail with postage prepaid. Notices to Licensee will be sent to the addresses
indicated in the applicable order for the Software and to the NICE contracting party at the address
in the opening paragraph of this EULA. Receipt shall be presumed received 5 business days after
mailing by first class mail unless the sender obtains a delivery receipt indicating it was delivered
earlier, the next day if sent by over-night courier, and when confirmation is received if by fax. In
addition, a copy of the notice shall also be given via e-mail to each party's primary contact. Either
party may designate a different address than that given below by notice to the other party in
accordance with this paragraph. A copy of any notice required or permitted to be sent to NICE shall
also be sent to Amazon.com, Inc. Attn: General Counsel P.O. Box 81226 Seattle, WA 98108-1226
Fax: (206) 266-7010 E-mail: contracts-legal@amazon.com.
(j) Modifications To The Agreement. NICE may modify this EULA at any time by posting a revised
version on the NICE website (nice-software.com, and any successor or related site designated by
NICE, hereinafter, the "NICE Website") or by sending a message to the email address then
associated with Licensee's account. Notices of modifications NICE provides by posting on the NICE
Website will be effective upon posting, and notices NICE provides by email will be effective when
NICE sends the email. It is Licensee's responsibility to keep its email address current. Licensee will
be deemed to have received any email sent to the email address then associated with its account
when NICE sends the email, whether or not Licensee actually receives the email. By continuing to
use the Software after the effective date of any modifications to this EULA, Licensee agrees to be
bound by the modified terms. It is Licensee's responsibility to check the NICE Website regularly for
modifications to this EULA.
(k) Trade Compliance. In connection with this EULA, Licensee will comply with all applicable
import, re-import, sanctions, anti-boycott, export, and re-export control laws and regulations,
including all such laws and regulations that apply to a U.S. company, such as the Export
Administration Regulations, the International Traffic in Arms Regulations, and economic sanctions
programs implemented by the Office of Foreign Assets Control. For clarity, Licensee is solely
responsible for compliance related to the manner in which Licensee chooses to use the Software.
Licensee represents and warrants that Licensee and its financial institutions, or any party that
owns or controls Licensee or its financial institutions, are not subject to sanctions or otherwise
designated on any list of prohibited or restricted parties, including the lists maintained by the
United Nations Security Council, the US Government (e.g., the US Department of Treasury's
Specially Designated Nationals list and Foreign Sanctions Evaders list and the US Department of
Commerce's Entity List), the European Union or its member states, or other applicable government
authority.
(l) U.S. Government Rights. The Software is provided to the U.S. Government as "commercial
items," "commercial computer software," "commercial computer software documentation," and
"technical data" with the same rights and restrictions generally applicable to the Software. If you
are using the Software on behalf of the U.S. Government and these terms fail to meet the U.S.
Government's needs or are inconsistent in any respect with federal law, Licensee will immediately
discontinue use of the Software. The terms "commercial item" "commercial computer software,"
"commercial computer software documentation," and "technical data" are defined in the Federal
Acquisition Regulation and the Defense Federal Acquisition Regulation Supplement.
(m) No Third-Party Beneficiaries. This EULA does not create any third-party beneficiary rights in any
individual or entity that is not a party to this EULA.
```

---

## Nvidia Driver; version 580.126.20 (550.127.08 on AL2)

<https://www.nvidia.com/download/index.aspx?lang=en-us>

```text

    * Package Nvidia Driver's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/nvidia_driver/NVIDIA-
Linux-x86_64-580.126.20.run
      (AL2 continues to use NVIDIA-Linux-x86_64-550.127.08.run)

NVIDIA Driver License Agreement

IMPORTANT NOTICE - PLEASE READ AND AGREE BEFORE USING THE SOFTWARE.

This license agreement ("Agreement") is a legal agreement between you, whether
an individual or entity ("you") and NVIDIA Corporation ("NVIDIA") and governs
your use of the NVIDIA driver, and any additional software and materials
provided (the "SOFTWARE").

If you don't have the required age or authority to enter into this Agreement or
if you don't accept all the terms below, do not use the SOFTWARE.

You agree to use the SOFTWARE only for purposes that are permitted by this
Agreement and any applicable law or regulation in the relevant jurisdictions.

1. License.

1.1 Subject to the terms of this Agreement, NVIDIA grants you a non-exclusive,
revocable, non-transferable and non-sublicensable (except as expressly provided
in this Agreement) license to:

a. Install and use copies of the SOFTWARE,

b. Modify and create derivative works of any portion of the SOFTWARE delivered
by NVIDIA in source code format,

c. Deploy, for your own use, the SOFTWARE on infrastructure you own or lease,
and

d. Distribute the SOFTWARE provided for use with operating system kernels
distributed under the terms of an OSI-approved open source license as listed by
the Open Source Initiative at http://opensource.org, provided that (i) the
binary files thereof are not modified in any way (except for uncompressing of
compressed files) and (ii) this Agreement is provided to each SOFTWARE
recipient.

2. Limitations.

The following license limitations apply to your use of the SOFTWARE:

2.1 The SOFTWARE is only licensed for use in conjunction with microprocessor(s),
SoCs, and GPUs which have been (i) designed by NVIDIA and/or its affiliates and
(ii) sold (directly or indirectly) by NVIDIA and/or its affiliates ("NVIDIA
Platform"). You may only use firmware in NVIDIA Platforms. You may not translate
firmware, nor cause or permit firmware to be translated, from the architecture
or language in which it is originally provided by NVIDIA, into any other
architecture or language.

2.2 You may not reverse engineer, decompile, or disassemble the SOFTWARE
provided in binary form, nor attempt in any other manner to obtain source code
of such SOFTWARE.

2.3 You may not modify or create derivative works of the SOFTWARE provided in
binary form.

2.4 You may not distribute any modified header files.

2.5 You may not change or remove copyright or other proprietary notices in the
SOFTWARE, or misrepresent the authorship of the SOFTWARE, and you must cause any
modified files to carry prominent notices stating that you changed the files
such that modifications are not misrepresented as an original SOFTWARE.

2.6 You may not bypass, disable, or circumvent any technical limitation,
encryption, security, digital rights management or authentication mechanism in
the SOFTWARE.

2.7 Except as expressly granted in this Agreement, you may not sell, rent,
sublicense, distribute or transfer the SOFTWARE or provide commercial hosting
services with the SOFTWARE.

2.8 You agree that GeForce or Titan SOFTWARE: (i) is licensed for use only on
GeForce or Titan hardware products you own, and (ii) is not licensed for
datacenter deployment.

2.9 You may not use the SOFTWARE in any manner that would cause it to become
subject to an open source software license, subject to the terms in the
"Components Under Other Licenses" section below.

2.10 You acknowledge that the SOFTWARE as delivered is not tested or certified
by NVIDIA for use in any system or application where the use of or failure of
such system or application developed with the SOFTWARE could result in injury,
death or catastrophic damage (each, a "Critical Application"). Examples of
Critical Applications include use in avionics, navigation, autonomous vehicle
applications, automotive products, military, medical, life support or other life
critical applications. NVIDIA will not be liable to you or any third party, in
whole or in part, for any claims or damages arising from these uses. You are
solely responsible for ensuring that systems and applications developed with the
SOFTWARE include sufficient safety and redundancy features, and comply with all
applicable legal and regulatory standards and requirements.

2.11 You agree to defend, indemnify and hold harmless NVIDIA and its affiliates,
and their respective employees, contractors, agents, officers and directors,
from and against any and all claims, damages, obligations, losses, liabilities,
costs or debt, fines, restitutions and expenses (including but not limited to
attorney's fees and costs incident to establishing the right of indemnification)
arising out of or related to products or services that have been developed with
or use the SOFTWARE (including for use in or for Critical Applications), and for
use of the SOFTWARE outside of the scope of this Agreement or not in compliance
with its terms.

3. Authorized Users.

You may allow employees and contractors of your entity or of your
subsidiary(ies) to access and use the SOFTWARE from your secure network to
perform the work authorized by this Agreement on your behalf.

If you are an academic institution, you may allow users enrolled or employed by
the academic institution to access and use the SOFTWARE as authorized by this
Agreement from your secure network.

You are responsible for the compliance with the terms of this Agreement by your
authorized users. Any act or omission that if committed by you would constitute
a breach of this Agreement will be deemed to constitute a breach of this
Agreement if committed by your authorized users.

4. Pre-Release SOFTWARE.

The SOFTWARE versions identified as alpha, beta, preview or otherwise as
pre-release may not be fully functional, may contain errors or design flaws, and
may have reduced or different security, privacy, accessibility and reliability
standards relative to commercial versions of NVIDIA software and materials.

You may use pre-release SOFTWARE at your own risk, understanding that
pre-release SOFTWARE is not intended for use in production or business-critical
systems and NVIDIA may choose not to make available a commercial version of any
pre-release SOFTWARE.

5. Support and Updates.

NVIDIA is not obligated to support any SOFTWARE, unless there is a separate
agreement for this purpose. NVIDIA may, at its option, make available patches,
workarounds or other updates to the SOFTWARE. Unless the updates are provided
with their separate governing terms, they are deemed part of the SOFTWARE
licensed to you as provided in this Agreement.

6. Components Under Other Licenses.

The SOFTWARE may include or be distributed with components provided with
separate legal notices or terms that accompany the components, such as open
source software licenses and other license terms ("Other Licenses"). The
components are subject to the applicable Other Licenses, including any
proprietary notices, disclaimers, requirements and extended use rights; except
that this Agreement will prevail regarding the use of third-party open source
software, unless a third-party open source software license requires its license
terms to prevail. Open source software license means any software, data or
documentation subject to any license identified as an open source license by the
Open Source Initiative (http://opensource.org), Free Software Foundation
(http://www.fsf.org) or other similar open source organization or listed by the
Software Package Data Exchange (SPDX) Workgroup under the Linux Foundation
(http://www.spdx.org).

You acknowledge and agree that it is your sole responsibility to obtain any
additional third-party licenses required to make, have made, use, have used,
sell, import, and offer for sale your products or services that include or
incorporate any third-party software and content, including, without limitation,
audio and/or video encoders and decoders and implementations of technical
standards. NVIDIA does not grant to you under this Agreement any necessary
patent or other rights, including standard essential patent rights, with respect
to any third-party software and content.

7. Termination.

This Agreement will automatically terminate without notice from NVIDIA if you
fail to comply with any of the terms in this Agreement or if you commence or
participate in any legal proceeding against NVIDIA with respect to the
SOFTWARE. Upon any termination, you must stop using and destroy all copies of
the SOFTWARE. You can terminate this Agreement whenever you want by stopping use
of the SOFTWARE and destroying all copies of the SOFTWARE. Your prior
distributions according to this Agreement are not affected by termination. All
provisions will survive termination, except for the licenses granted to you.

8. Ownership.

The SOFTWARE, including all intellectual property rights, is and will remain the
sole and exclusive property of NVIDIA or its licensors. Except as expressly
granted in this Agreement, (i) NVIDIA reserves all rights, interests, and
remedies in connection with the SOFTWARE, and (ii) no other license or right is
granted to you by implication, estoppel or otherwise. You agree to cooperate
with NVIDIA and provide reasonably requested information to verify your
compliance with this Agreement.

9. Feedback.

You may, but you are not obligated to, provide suggestions, requests, fixes,
modifications, enhancements, or other feedback regarding the SOFTWARE
(collectively, "Feedback"). Feedback, even if designated as confidential by you,
will not create any confidentiality obligation for NVIDIA or its affiliates. If
you provide Feedback, you grant NVIDIA, its affiliates and its designees a
non-exclusive, perpetual, irrevocable, sublicensable, worldwide, royalty-free,
fully paid-up and transferable license, under your intellectual property rights,
to publicly perform, publicly display, reproduce, use, make, have made, sell,
offer for sale, distribute (through multiple tiers of distribution), import,
create derivative works of and otherwise commercialize and exploit the Feedback
at NVIDIA's discretion. You will not give Feedback (i) that you have reason to
believe is subject to any restriction that impairs the exercise of the grant
stated in this section; or (ii) subject to license terms which seek to require
any product incorporating or developed using such Feedback, or other
intellectual property of NVIDIA or its affiliates, to be licensed to or
otherwise shared with any third party.

10. Governing Law and Dispute Resolution.

10.1 Informal Resolution.

If you or NVIDIA have any dispute, claim or controversy arising out of or
relating to the SOFTWARE or this Agreement ("Dispute"), the parties agree to
work in good faith to resolve the Dispute informally. If you have a Dispute, you
must first contact NVIDIA and give NVIDIA an opportunity to resolve it by
contacting NVIDIA by mail at NVIDIA Corporation, ATTN: Legal, 2788 San Tomas
Expressway, Santa Clara, California, 95051. Either you or NVIDIA may seek to
have a Dispute resolved in small claims court if all the requirements of the
small claims court are satisfied. Either you or NVIDIA may seek to have a
Dispute resolved in small claims court in your county of residence or the small
claims court in closest proximity to your residence at any time before an
arbitrator is appointed, and you may also bring a Dispute in small claims court
in the Superior Court of California, County of Santa Clara.

10.2 Binding Arbitration.

For any Disputes that are not resolved informally or by the small claims court,
you and NVIDIA each agree to resolve any such Dispute by binding arbitration
before an arbitrator from Judicial Mediation and Arbitration Services ("JAMS")
(rules available at https://www.jamsadr.com/). Except as otherwise provided in
this section, all issues are for the arbitrator to decide, including
jurisdictional and arbitrability issues and the formation, existence, validity,
interpretation, and scope of this arbitration provision. The arbitration will be
conducted in Santa Clara County, California (or the nearest JAMS office to Santa
Clara County), unless you request an in-person hearing in your hometown or you
and NVIDIA agree otherwise. You and NVIDIA agree that the parties will arbitrate
all Disputes, remedies, and requests for relief subject to individual
arbitration first, the arbitrator will only determine issues of liability on the
merits of any claim asserted, and the arbitrator may only award declaratory or
injunctive relief in favor of the individual party seeking relief and only to
the extent necessary to provide relief warranted by that party's individual
claim. You and NVIDIA agree that any remaining unresolved Disputes, remedies, or
requests for relief may be pursued in court only after the arbitrator's award
has been issued. In any later court proceeding, the arbitrator's factual
findings will not be entitled to deference by the court. Nothing in these terms
will prevent a party from seeking injunctive or other equitable relief from the
courts in any jurisdiction to prevent the actual or threatened violation of that
party's data security, intellectual property rights, or other proprietary
rights. If for any reason this Section 10.2 is unenforceable concerning any
Dispute, and a Dispute proceeds in a court of general jurisdiction, the Dispute
will be exclusively brought in state or federal court located in Santa Clara
County, California.

10.3 Class Action, Representative Action, & Jury Trial Waiver.

All Disputes must be brought by a party in its individual capacity, and not as a
plaintiff or class member in any purported class or representative
proceeding. You and NVIDIA agree to waive the right to a jury trial, participate
in class action lawsuits, class-wide arbitrations, any collective, consolidated,
or other proceeding or request for relief where someone acts in a representative
capacity.

10.4 Right to Opt-Out.

You may opt-out of the foregoing jury trial, class action, arbitration, and
collective or consolidated proceeding waiver provision by notifying NVIDIA in
writing within 30 days of commencement of use of the SOFTWARE, within 30 days of
the effective date of this Agreement, or within 30 days of any future change
NVIDIA may make to this Section 10.4. Such written notification must be sent by
mail to NVIDIA Corporation, Attn: Legal, 2788 San Tomas Expressway, Santa Clara,
California, 95051 and must include (1) your name, (2) your address, (3) the
reference to NVIDIA drivers as the software to which the notice relates, and (4)
a clear statement indicating that you do not wish to resolve disputes through
arbitration and demonstrating compliance with the 30-day time limit to
opt-out. Any opt-out notification received after the opt-out deadline or not
including the required items noted in (1)-(4) in the preceding sentence will not
be valid and you will be required to pursue your Dispute in arbitration or small
claims court. Opting out of this dispute resolution procedure will not affect
the terms and conditions of this Agreement, which still apply to you. If you
opt-out of any future change NVIDIA may make to this Section 10.4, the most
recent version of Section 10.4 before the change you rejected will apply.

10.5 Governing Law.

You and NVIDIA each agree that all Disputes will be governed by the Federal
Arbitration Act, in addition to the internal substantive laws of the State of
Delaware and the United States, without regard to or application of its conflict
of laws rules or principles. The United Nations Convention on Contracts for the
International Sale of Goods is expressly disclaimed. Any translation of this
Agreement is done for local requirements and, if there is a dispute between the
English and any non-English versions, you and NVIDIA agree that the English
version of this Agreement will govern to the extent not prohibited by local law
in your jurisdiction.

11. Disclaimer of Warranties.

THE SOFTWARE IS PROVIDED BY NVIDIA AS-IS AND WITH ALL FAULTS. TO THE FULLEST
EXTENT PERMITTED BY APPLICABLE LAW, NVIDIA DISCLAIMS ALL WARRANTIES AND
REPRESENTATIONS OF ANY KIND, WHETHER EXPRESS, IMPLIED OR STATUTORY, RELATING TO
OR ARISING UNDER THIS AGREEMENT, INCLUDING, WITHOUT LIMITATION, THE WARRANTIES
OF TITLE, NONINFRINGEMENT, MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
USAGE OF TRADE AND COURSE OF DEALING. WITHOUT LIMITING THE FOREGOING, NVIDIA
DOES NOT WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS; THAT ANY DEFECTS
OR ERRORS WILL BE CORRECTED; THAT ANY CERTAIN CONTENT WILL BE AVAILABLE; OR THAT
THE SOFTWARE IS FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.

In addition, you agree that you are solely responsible for maintaining
appropriate data backups and system restore points for systems that include the
SOFTWARE, and that NVIDIA will have no responsibility for any damage or loss to
such systems (including loss of data or access) arising from or relating to (a)
any changes to the configuration, application settings, environment variables,
registry, drivers, BIOS, or other attributes of the system (or any part of such
system) initiated through the SOFTWARE; or (b) installation of any SOFTWARE or
third party software patches through the NVIDIA update service.

NO INFORMATION OR ADVICE GIVEN BY NVIDIA WILL IN ANY WAY INCREASE THE SCOPE OF
ANY WARRANTY EXPRESSLY PROVIDED IN THIS AGREEMENT. You are responsible for
checking that a SOFTWARE version is the appropriate one for your NVIDIA product
model, operating system, and computer hardware.

12. Limitations of Liability.

TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT WILL NVIDIA BE
LIABLE FOR ANY (I) INDIRECT, PUNITIVE, SPECIAL, INCIDENTAL OR CONSEQUENTIAL
DAMAGES, OR (II) DAMAGES FOR (A) THE COST OF PROCURING SUBSTITUTE GOODS, OR (B)
LOSS OF PROFITS, REVENUES, USE, DATA OR GOODWILL ARISING OUT OF OR RELATED TO
THIS AGREEMENT, WHETHER BASED ON BREACH OF CONTRACT, TORT (INCLUDING
NEGLIGENCE), STRICT LIABILITY, OR OTHERWISE, AND EVEN IF NVIDIA HAS BEEN ADVISED
OF THE POSSIBILITY OF SUCH DAMAGES AND EVEN IF A PARTY'S REMEDIES FAIL THEIR
ESSENTIAL PURPOSE.

ADDITIONALLY, TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, NVIDIA'S TOTAL
CUMULATIVE AGGREGATE LIABILITY FOR ANY AND ALL LIABILITIES, OBLIGATIONS OR
CLAIMS ARISING OUT OF OR RELATED TO THIS AGREEMENT WILL NOT EXCEED FIVE
U.S. DOLLARS (US$5).

13. Data Collection.

If you are using the SOFTWARE on a Windows operating system, you hereby
acknowledge that at the time of SOFTWARE installation, NVIDIA will access and
collect data to: (a) properly configure and optimize the system for use with the
SOFTWARE; (b) deliver content or service through SOFTWARE; and (c) improve
NVIDIA products and services. Information collected may include configuration
data such as GPU and CPU, and operating system.

The SOFTWARE may contain links to third party websites and services. NVIDIA
encourages you to review the privacy statements on those sites and services that
you choose to visit to understand how they may collect, use and share your
data. NVIDIA is not responsible for the privacy statements or practices of third
party sites or services.

Please review the NVIDIA Privacy Policy, located at
https://www.nvidia.com/en-us/about-nvidia/privacy-policy, which explains
NVIDIA's policy for collecting and using data.

14. Assignment.

NVIDIA may assign, delegate or transfer its rights or obligations under this
Agreement by any means or operation of law. You may not, without NVIDIA's prior
written consent, assign, delegate or transfer any of its rights or obligations
under this Agreement by any means or operation of law, and any attempt to do so
is null and void.

15. Trade Compliance.

You agree to comply with all applicable export, import, trade and economic
sanctions laws and regulations, including U.S. Export Administration
Regulations and Office of Foreign Assets Control regulations. These laws include
restrictions on destinations, end-users and end-use.

16. Government Use.

The SOFTWARE, including related documentation ("Protected Items") is a
"Commercial product" as this term is defined at 48 C.F.R. 2.101, consisting of
"commercial computer software" and "commercial computer software documentation"
as such terms are used in, respectively, 48 C.F.R. 12.212 and 48 C.F.R. 227.7202
& 252.227-7014(a)(1). Before any Protected Items are supplied to the
U.S. Government, you will (i) inform the U.S. Government in writing that the
Protected Items are and must be treated as commercial computer software and
commercial computer software documentation developed at private expense; (ii)
inform the U.S. Government that the Protected Items are provided subject to the
terms of this Agreement; and (iii) mark the Protected Items as commercial
computer software and commercial computer software documentation developed at
private expense. In no event will you permit the U.S. Government to acquire
rights in Protected Items beyond those specified in 48
C.F.R. 52.227-19(b)(1)-(2) or 252.227-7013(c) except as expressly approved by
NVIDIA in writing.

17. Notices.

Please direct your legal notices or other correspondence to NVIDIA Corporation,
2788 San Tomas Expressway, Santa Clara, California 95051, United States of
America, Attention: Legal Department. If NVIDIA needs to contact you about the
SOFTWARE, you consent to receive the notices by email and that such notices will
satisfy any legal communication requirements.

18. Entire Agreement.

Regarding the subject matter of this Agreement, the parties agree that (i) this
Agreement constitutes the entire and exclusive agreement between the parties and
supersedes all prior and contemporaneous communications and (ii) any additional
or different terms or conditions, whether contained in purchase orders, order
acknowledgments, invoices or otherwise, will not be binding on the receiving
party and are null and void. This Agreement may only be modified in a writing
signed by an authorized representative of each party.

If a court of competent jurisdiction rules that a provision of this Agreement is
unenforceable, that provision will be deemed modified to the extent necessary to
make it enforceable and the remainder of this Agreement will continue in full
force and effect.

19. No Waiver.

No failure or delay by a party to enforce any Agreement term or obligation will
operate as a waiver by that party, or prevent the enforcement of such term or
obligation later.

20. Licensing.

For any questions regarding this Agreement, please contact NVIDIA at
driver-licensing@nvidia.com

(v. February 25, 2025)
```

---

## Cuda Samples; version 13.0 (12.4 on AL2)

<https://github.com/NVIDIA/cuda-samples/>

```text
Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.

    * Package Cuda Samples's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/cuda/samples/v13.0.tar.gz
      (AL2 continues to use https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/cuda/samples/v12.4.tar.gz)

1.1. License
1.1.1. License Grant
Subject to the terms of this Agreement, NVIDIA hereby grants you a non-
exclusive, non-transferable license, without the right to sublicense (except as
expressly provided in this Agreement) to:

Install and use the SDK,

Modify and create derivative works of sample source code delivered in the SDK,
and

Distribute those portions of the SDK that are identified in this Agreement as
distributable, as incorporated in object code format into a software application
that meets the distribution requirements indicated in this Agreement.

1.1.2. Distribution Requirements
These are the distribution requirements for you to exercise the distribution
grant:

Your application must have material additional functionality, beyond the
included portions of the SDK.

The distributable portions of the SDK shall only be accessed by your
application.

The following notice shall be included in modifications and derivative works of
sample source code distributed: “This software contains source code provided by
NVIDIA Corporation.”

Unless a developer tool is identified in this Agreement as distributable, it is
delivered for your internal use only.

The terms under which you distribute your application must be consistent with
the terms of this Agreement, including (without limitation) terms relating to
the license grant and license restrictions and protection of NVIDIA’s
intellectual property rights. Additionally, you agree that you will protect the
privacy, security and legal rights of your application users.

You agree to notify NVIDIA in writing of any known or suspected distribution or
use of the SDK not in compliance with the requirements of this Agreement, and to
enforce the terms of your agreements with respect to distributed SDK.

1.1.3. Authorized Users
You may allow employees and contractors of your entity or of your
subsidiary(ies) to access and use the SDK from your secure network to perform
work on your behalf.

If you are an academic institution you may allow users enrolled or employed by
the academic institution to access and use the SDK from your secure network.

You are responsible for the compliance with the terms of this Agreement by your
authorized users. If you become aware that your authorized users didn’t follow
the terms of this Agreement, you agree to take reasonable steps to resolve the
non-compliance and prevent new occurrences.

1.1.4. Pre-Release SDK
The SDK versions identified as alpha, beta, preview or otherwise as pre-release,
may not be fully functional, may contain errors or design flaws, and may have
reduced or different security, privacy, accessibility, availability, and
reliability standards relative to commercial versions of NVIDIA software and
materials. Use of a pre-release SDK may result in unexpected results, loss of
data, project delays or other unpredictable damage or loss.

You may use a pre-release SDK at your own risk, understanding that pre-release
SDKs are not intended for use in production or business-critical systems.

NVIDIA may choose not to make available a commercial version of any pre-release
SDK. NVIDIA may also choose to abandon development and terminate the
availability of a pre-release SDK at any time without liability.

1.1.5. Updates
NVIDIA may, at its option, make available patches, workarounds or other updates
to this SDK. Unless the updates are provided with their separate governing
terms, they are deemed part of the SDK licensed to you as provided in this
Agreement. You agree that the form and content of the SDK that NVIDIA provides
may change without prior notice to you. While NVIDIA generally maintains
compatibility between versions, NVIDIA may in some cases make changes that
introduce incompatibilities in future versions of the SDK.

1.1.6. Components Under Other Licenses
The SDK may come bundled with, or otherwise include or be distributed with,
NVIDIA or third-party components with separate legal notices or terms as may be
described in proprietary notices accompanying the SDK. If and to the extent
there is a conflict between the terms in this Agreement and the license terms
associated with the component, the license terms associated with the components
control only to the extent necessary to resolve the conflict.

Subject to the other terms of this Agreement, you may use the SDK to develop and
test applications released under Open Source Initiative (OSI) approved open
source software licenses.

1.1.7. Reservation of Rights
NVIDIA reserves all rights, title, and interest in and to the SDK, not expressly
granted to you under this Agreement.

1.2. Limitations
The following license limitations apply to your use of the SDK:

You may not reverse engineer, decompile or disassemble, or remove copyright or
other proprietary notices from any portion of the SDK or copies of the SDK.

Except as expressly provided in this Agreement, you may not copy, sell, rent,
sublicense, transfer, distribute, modify, or create derivative works of any
portion of the SDK. For clarity, you may not distribute or sublicense the SDK as
a stand-alone product.

Unless you have an agreement with NVIDIA for this purpose, you may not indicate
that an application created with the SDK is sponsored or endorsed by NVIDIA.

You may not bypass, disable, or circumvent any encryption, security, digital
rights management or authentication mechanism in the SDK.

You may not use the SDK in any manner that would cause it to become subject to
an open source software license. As examples, licenses that require as a
condition of use, modification, and/or distribution that the SDK be:

Disclosed or distributed in source code form;

Licensed for the purpose of making derivative works; or

Redistributable at no charge.

You acknowledge that the SDK as delivered is not tested or certified by NVIDIA
for use in connection with the design, construction, maintenance, and/or
operation of any system where the use or failure of such system could result in
a situation that threatens the safety of human life or results in catastrophic
damages (each, a “Critical Application”). Examples of Critical Applications
include use in avionics, navigation, autonomous vehicle applications, ai
solutions for automotive products, military, medical, life support or other life
critical applications. NVIDIA shall not be liable to you or any third party, in
whole or in part, for any claims or damages arising from such uses. You are
solely responsible for ensuring that any product or service developed with the
SDK as a whole includes sufficient features to comply with all applicable legal
and regulatory standards and requirements.

You agree to defend, indemnify and hold harmless NVIDIA and its affiliates, and
their respective employees, contractors, agents, officers and directors, from
and against any and all claims, damages, obligations, losses, liabilities, costs
or debt, fines, restitutions and expenses (including but not limited to
attorney’s fees and costs incident to establishing the right of indemnification)
arising out of or related to products or services that use the SDK in or for
Critical Applications, and for use of the SDK outside of the scope of this
Agreement or not in compliance with its terms.

You may not reverse engineer, decompile or disassemble any portion of the output
generated using SDK elements for the purpose of translating such output
artifacts to target a non-NVIDIA platform.

1.3. Ownership
NVIDIA or its licensors hold all rights, title and interest in and to the SDK
and its modifications and derivative works, including their respective
intellectual property rights, subject to your rights under Section 1.3.2. This
SDK may include software and materials from NVIDIA’s licensors, and these
licensors are intended third party beneficiaries that may enforce this Agreement
with respect to their intellectual property rights.

You hold all rights, title and interest in and to your applications and your
derivative works of the sample source code delivered in the SDK, including their
respective intellectual property rights, subject to NVIDIA’s rights under
Section 1.3.1.

You may, but don’t have to, provide to NVIDIA suggestions, feature requests or
other feedback regarding the SDK, including possible enhancements or
modifications to the SDK. For any feedback that you voluntarily provide, you
hereby grant NVIDIA and its affiliates a perpetual, non-exclusive, worldwide,
irrevocable license to use, reproduce, modify, license, sublicense (through
multiple tiers of sublicensees), and distribute (through multiple tiers of
distributors) it without the payment of any royalties or fees to you. NVIDIA
will use feedback at its choice. NVIDIA is constantly looking for ways to
improve its products, so you may send feedback to NVIDIA through the developer
portal at https://developer.nvidia.com.

1.4. No Warranties
THE SDK IS PROVIDED BY NVIDIA “AS IS” AND “WITH ALL FAULTS.” TO THE MAXIMUM
EXTENT PERMITTED BY LAW, NVIDIA AND ITS AFFILIATES EXPRESSLY DISCLAIM ALL
WARRANTIES OF ANY KIND OR NATURE, WHETHER EXPRESS, IMPLIED OR STATUTORY,
INCLUDING, BUT NOT LIMITED TO, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, OR THE ABSENCE OF ANY DEFECTS
THEREIN, WHETHER LATENT OR PATENT. NO WARRANTY IS MADE ON THE BASIS OF TRADE
USAGE, COURSE OF DEALING OR COURSE OF TRADE.

1.5. Limitation of Liability
TO THE MAXIMUM EXTENT PERMITTED BY LAW, NVIDIA AND ITS AFFILIATES SHALL NOT BE
LIABLE FOR ANY (I) SPECIAL, INCIDENTAL, PUNITIVE OR CONSEQUENTIAL DAMAGES, OR
(II) DAMAGES FOR (A) ANY LOST PROFITS, LOSS OF USE, LOSS OF DATA OR LOSS OF
GOODWILL, OR (B) THE COSTS OF PROCURING SUBSTITUTE PRODUCTS, ARISING OUT OF OR
IN CONNECTION WITH THIS AGREEMENT OR THE USE OR PERFORMANCE OF THE SDK, WHETHER
SUCH LIABILITY ARISES FROM ANY CLAIM BASED UPON BREACH OF CONTRACT, BREACH OF
WARRANTY, TORT (INCLUDING NEGLIGENCE), PRODUCT LIABILITY OR ANY OTHER CAUSE OF
ACTION OR THEORY OF LIABILITY. IN NO EVENT WILL NVIDIA’S AND ITS AFFILIATES
TOTAL CUMULATIVE LIABILITY UNDER OR ARISING OUT OF THIS AGREEMENT EXCEED
US$10.00. THE NATURE OF THE LIABILITY OR THE NUMBER OF CLAIMS OR SUITS SHALL NOT
ENLARGE OR EXTEND THIS LIMIT.

These exclusions and limitations of liability shall apply regardless if NVIDIA
or its affiliates have been advised of the possibility of such damages, and
regardless of whether a remedy fails its essential purpose. These exclusions and
limitations of liability form an essential basis of the bargain between the
parties, and, absent any of these exclusions or limitations of liability, the
provisions of this Agreement, including, without limitation, the economic terms,
would be substantially different.

1.6. Termination
This Agreement will continue to apply until terminated by either you or NVIDIA
as described below.

If you want to terminate this Agreement, you may do so by stopping to use the
SDK.

NVIDIA may, at any time, terminate this Agreement if:

(i) you fail to comply with any term of this Agreement and the non-compliance is
not fixed within thirty (30) days following notice from NVIDIA (or immediately
if you violate NVIDIA’s intellectual property rights);

(ii) you commence or participate in any legal proceeding against NVIDIA with
respect to the SDK; or

(iii) NVIDIA decides to no longer provide the SDK in a country or, in NVIDIA’s
sole discretion, the continued use of it is no longer commercially viable.

Upon any termination of this Agreement, you agree to promptly discontinue use of
the SDK and destroy all copies in your possession or control. Your prior
distributions in accordance with this Agreement are not affected by the
termination of this Agreement. Upon written request, you will certify in writing
that you have complied with your commitments under this section. Upon any
termination of this Agreement all provisions survive except for the license
grant provisions.

1.7. General
If you wish to assign this Agreement or your rights and obligations, including
by merger, consolidation, dissolution or operation of law, contact NVIDIA to ask
for permission. Any attempted assignment not approved by NVIDIA in writing shall
be void and of no effect. NVIDIA may assign, delegate or transfer this Agreement
and its rights and obligations, and if to a non-affiliate you will be notified.

You agree to cooperate with NVIDIA and provide reasonably requested information
to verify your compliance with this Agreement.

This Agreement will be governed in all respects by the laws of the United States
and of the State of Delaware, without regard to the conflicts of laws
principles. The United Nations Convention on Contracts for the International
Sale of Goods is specifically disclaimed. You agree to all terms of this
Agreement in the English language.

The state or federal courts residing in Santa Clara County, California shall
have exclusive jurisdiction over any dispute or claim arising out of this
Agreement. Notwithstanding this, you agree that NVIDIA shall still be allowed to
apply for injunctive remedies or an equivalent type of urgent legal relief in
any jurisdiction.

If any court of competent jurisdiction determines that any provision of this
Agreement is illegal, invalid or unenforceable, such provision will be construed
as limited to the extent necessary to be consistent with and fully enforceable
under the law and the remaining provisions will remain in full force and effect.
Unless otherwise specified, remedies are cumulative.

Each party acknowledges and agrees that the other is an independent contractor
in the performance of this Agreement.

The SDK has been developed entirely at private expense and is “commercial items”
consisting of “commercial computer software” and “commercial computer software
documentation” provided with RESTRICTED RIGHTS. Use, duplication or disclosure
by the U.S. Government or a U.S. Government subcontractor is subject to the
restrictions in this Agreement pursuant to DFARS 227.7202-3(a) or as set forth
in subparagraphs (c)(1) and (2) of the Commercial Computer Software - Restricted
Rights clause at FAR 52.227-19, as applicable. Contractor/manufacturer is
NVIDIA, 2788 San Tomas Expressway, Santa Clara, CA 95051.

The SDK is subject to United States export laws and regulations. You agree that
you will not ship, transfer or export the SDK into any country, or use the SDK
in any manner, prohibited by the United States Bureau of Industry and Security
or economic sanctions regulations administered by the U.S. Department of
Treasury’s Office of Foreign Assets Control (OFAC), or any applicable export
laws, restrictions or regulations. These laws include restrictions on
destinations, end users and end use. By accepting this Agreement, you confirm
that you are not located in a country currently embargoed by the U.S. or
otherwise prohibited from receiving the SDK under U.S. law.

Any notice delivered by NVIDIA to you under this Agreement will be delivered via
mail, email or fax. You agree that any notices that NVIDIA sends you
electronically will satisfy any legal communication requirements. Please direct
your legal notices or other correspondence to NVIDIA Corporation, 2788 San Tomas
Expressway, Santa Clara, California 95051, United States of America, Attention:
Legal Department.

This Agreement and any exhibits incorporated into this Agreement constitute the
entire agreement of the parties with respect to the subject matter of this
Agreement and supersede all prior negotiations or documentation exchanged
between the parties relating to this SDK license. Any additional and/or
conflicting terms on documents issued by you are null, void, and invalid. Any
amendment or waiver under this Agreement shall be in writing and signed by
representatives of both parties.
```

---

## Nvidia CUDA; version 13.0.2 (12.4.1 on AL2)

<https://developer.nvidia.com/cuda-toolkit>

```text
Copyright (c) 2007-2025 NVIDIA Corporation. All rights reserved.

    * Package Nvidia CUDA's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-
east-1.amazonaws.com/archives/dependencies/cuda/cuda_13.0.2_580.95.05_linux.run
      (AL2 continues to use cuda_12.4.1_550.54.15_linux.run)

End User License Agreement
--------------------------

NVIDIA Software License Agreement and CUDA Supplement to
Software License Agreement.

The CUDA Toolkit End User License Agreement applies to the
NVIDIA CUDA Toolkit, the NVIDIA CUDA Samples, the NVIDIA
Display Driver, NVIDIA Nsight tools (Visual Studio Edition),
and the associated documentation on CUDA APIs, programming
model and development tools. If you do not agree with the
terms and conditions of the license agreement, then do not
download or use the software.

Last updated: January 12, 2025


Preface
-------

The Software License Agreement in Chapter 1 and the Supplement
in Chapter 2 contain license terms and conditions that govern
the use of NVIDIA toolkit. By accepting this agreement, you
agree to comply with all the terms and conditions applicable
to the product(s) included herein.


NVIDIA Driver


Description

This package contains the operating system driver and
fundamental system software components for NVIDIA GPUs.


NVIDIA CUDA Toolkit


Description

The NVIDIA CUDA Toolkit provides command-line and graphical
tools for building, debugging and optimizing the performance
of applications accelerated by NVIDIA GPUs, runtime and math
libraries, and documentation including programming guides,
user manuals, and API references.


Default Install Location of CUDA Toolkit

Windows platform:

%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v#.#

Linux platform:

/usr/local/cuda-#.#

Mac platform:

/Developer/NVIDIA/CUDA-#.#


NVIDIA CUDA Samples


Description

CUDA Samples are now located in
https://github.com/nvidia/cuda-samples, which includes
instructions for obtaining, building, and running the samples.
They are no longer included in the CUDA toolkit.


NVIDIA Nsight Visual Studio Edition (Windows only)


Description

NVIDIA Nsight Development Platform, Visual Studio Edition is a
development environment integrated into Microsoft Visual
Studio that provides tools for debugging, profiling, analyzing
and optimizing your GPU computing and graphics applications.


Default Install Location of Nsight Visual Studio Edition

Windows platform:

%ProgramFiles(x86)%\NVIDIA Corporation\Nsight Visual Studio Edition #.#


1. License Agreement for NVIDIA Software Development Kits
---------------------------------------------------------


Important Notice—Read before downloading, installing,
copying or using the licensed software:
-------------------------------------------------------

This license agreement, including exhibits attached
("Agreement”) is a legal agreement between you and NVIDIA
Corporation ("NVIDIA") and governs your use of a NVIDIA
software development kit (“SDK”).

Each SDK has its own set of software and materials, but here
is a description of the types of items that may be included in
a SDK: source code, header files, APIs, data sets and assets
(examples include images, textures, models, scenes, videos,
native API input/output files), binary software, sample code,
libraries, utility programs, programming code and
documentation.

This Agreement can be accepted only by an adult of legal age
of majority in the country in which the SDK is used.

If you are entering into this Agreement on behalf of a company
or other legal entity, you represent that you have the legal
authority to bind the entity to this Agreement, in which case
“you” will mean the entity you represent.

If you don’t have the required age or authority to accept
this Agreement, or if you don’t accept all the terms and
conditions of this Agreement, do not download, install or use
the SDK.

You agree to use the SDK only for purposes that are permitted
by (a) this Agreement, and (b) any applicable law, regulation
or generally accepted practices or guidelines in the relevant
jurisdictions.


1.1. License


1.1.1. License Grant

Subject to the terms of this Agreement, NVIDIA hereby grants
you a non-exclusive, non-transferable license, without the
right to sublicense (except as expressly provided in this
Agreement) to:

  1. Install and use the SDK,

  2. Modify and create derivative works of sample source code
    delivered in the SDK, and

  3. Distribute those portions of the SDK that are identified
    in this Agreement as distributable, as incorporated in
    object code format into a software application that meets
    the distribution requirements indicated in this Agreement.


1.1.2. Distribution Requirements

These are the distribution requirements for you to exercise
the distribution grant:

  1. Your application must have material additional
    functionality, beyond the included portions of the SDK.

  2. The distributable portions of the SDK shall only be
    accessed by your application.

  3. The following notice shall be included in modifications
    and derivative works of sample source code distributed:
    “This software contains source code provided by NVIDIA
    Corporation.”

  4. Unless a developer tool is identified in this Agreement
    as distributable, it is delivered for your internal use
    only.

  5. The terms under which you distribute your application
    must be consistent with the terms of this Agreement,
    including (without limitation) terms relating to the
    license grant and license restrictions and protection of
    NVIDIA’s intellectual property rights. Additionally, you
    agree that you will protect the privacy, security and
    legal rights of your application users.

  6. You agree to notify NVIDIA in writing of any known or
    suspected distribution or use of the SDK not in compliance
    with the requirements of this Agreement, and to enforce
    the terms of your agreements with respect to distributed
    SDK.


1.1.3. Authorized Users

You may allow employees and contractors of your entity or of
your subsidiary(ies) to access and use the SDK from your
secure network to perform work on your behalf.

If you are an academic institution you may allow users
enrolled or employed by the academic institution to access and
use the SDK from your secure network.

You are responsible for the compliance with the terms of this
Agreement by your authorized users. If you become aware that
your authorized users didn’t follow the terms of this
Agreement, you agree to take reasonable steps to resolve the
non-compliance and prevent new occurrences.


1.1.4. Pre-Release SDK

The SDK versions identified as alpha, beta, preview or
otherwise as pre-release, may not be fully functional, may
contain errors or design flaws, and may have reduced or
different security, privacy, accessibility, availability, and
reliability standards relative to commercial versions of
NVIDIA software and materials. Use of a pre-release SDK may
result in unexpected results, loss of data, project delays or
other unpredictable damage or loss.

You may use a pre-release SDK at your own risk, understanding
that pre-release SDKs are not intended for use in production
or business-critical systems.

NVIDIA may choose not to make available a commercial version
of any pre-release SDK. NVIDIA may also choose to abandon
development and terminate the availability of a pre-release
SDK at any time without liability.


1.1.5. Updates

NVIDIA may, at its option, make available patches, workarounds
or other updates to this SDK. Unless the updates are provided
with their separate governing terms, they are deemed part of
the SDK licensed to you as provided in this Agreement. You
agree that the form and content of the SDK that NVIDIA
provides may change without prior notice to you. While NVIDIA
generally maintains compatibility between versions, NVIDIA may
in some cases make changes that introduce incompatibilities in
future versions of the SDK.


1.1.6. Components Under Other Licenses

The SDK may come bundled with, or otherwise include or be
distributed with, NVIDIA or third-party components with
separate legal notices or terms as may be described in
proprietary notices accompanying the SDK. If and to the extent
there is a conflict between the terms in this Agreement and
the license terms associated with the component, the license
terms associated with the components control only to the
extent necessary to resolve the conflict.

Subject to the other terms of this Agreement, you may use the
SDK to develop and test applications released under Open
Source Initiative (OSI) approved open source software
licenses.


1.1.7. Reservation of Rights

NVIDIA reserves all rights, title, and interest in and to the
SDK, not expressly granted to you under this Agreement.


1.2. Limitations

The following license limitations apply to your use of the
SDK:

  1. You may not reverse engineer, decompile or disassemble,
    or remove copyright or other proprietary notices from any
    portion of the SDK or copies of the SDK.

  2. Except as expressly provided in this Agreement, you may
    not copy, sell, rent, sublicense, transfer, distribute,
    modify, or create derivative works of any portion of the
    SDK. For clarity, you may not distribute or sublicense the
    SDK as a stand-alone product.

  3. Unless you have an agreement with NVIDIA for this
    purpose, you may not indicate that an application created
    with the SDK is sponsored or endorsed by NVIDIA.

  4. You may not bypass, disable, or circumvent any
    encryption, security, digital rights management or
    authentication mechanism in the SDK.

  5. You may not use the SDK in any manner that would cause it
    to become subject to an open source software license. As
    examples, licenses that require as a condition of use,
    modification, and/or distribution that the SDK be:

      a. Disclosed or distributed in source code form;

      b. Licensed for the purpose of making derivative works;
        or

      c. Redistributable at no charge.

  6.  You acknowledge that the SDK as delivered is not tested
    or certified by NVIDIA for use in connection with the
    design, construction, maintenance, and/or operation of any
    system where the use or failure of such system could
    result in a situation that threatens the safety of human
    life or results in catastrophic damages (each, a "Critical
    Application"). Examples of Critical Applications include
    use in avionics, navigation, autonomous vehicle
    applications, ai solutions for automotive products,
    military, medical, life support or other life critical
    applications. NVIDIA shall not be liable to you or any
    third party, in whole or in part, for any claims or
    damages arising from such uses. You are solely responsible
    for ensuring that any product or service developed with
    the SDK as a whole includes sufficient features to comply
    with all applicable legal and regulatory standards and
    requirements.

  7.  You agree to defend, indemnify and hold harmless NVIDIA
    and its affiliates, and their respective employees,
    contractors, agents, officers and directors, from and
    against any and all claims, damages, obligations, losses,
    liabilities, costs or debt, fines, restitutions and
    expenses (including but not limited to attorney’s fees
    and costs incident to establishing the right of
    indemnification) arising out of or related to products or
    services that use the SDK in or for Critical Applications,
    and for use of the SDK outside of the scope of this
    Agreement or not in compliance with its terms.

  8. You may not reverse engineer, decompile or disassemble
    any portion of the output generated using SDK elements for
    the purpose of translating such output artifacts to target
    a non-NVIDIA platform.


1.3. Ownership

  1.  NVIDIA or its licensors hold all rights, title and
    interest in and to the SDK and its modifications and
    derivative works, including their respective intellectual
    property rights, subject to your rights under Section
    1.3.2. This SDK may include software and materials from
    NVIDIA’s licensors, and these licensors are intended
    third party beneficiaries that may enforce this Agreement
    with respect to their intellectual property rights.

  2.  You hold all rights, title and interest in and to your
    applications and your derivative works of the sample
    source code delivered in the SDK, including their
    respective intellectual property rights, subject to
    NVIDIA’s rights under Section 1.3.1.

  3. You may, but don’t have to, provide to NVIDIA
    suggestions, feature requests or other feedback regarding
    the SDK, including possible enhancements or modifications
    to the SDK. For any feedback that you voluntarily provide,
    you hereby grant NVIDIA and its affiliates a perpetual,
    non-exclusive, worldwide, irrevocable license to use,
    reproduce, modify, license, sublicense (through multiple
    tiers of sublicensees), and distribute (through multiple
    tiers of distributors) it without the payment of any
    royalties or fees to you. NVIDIA will use feedback at its
    choice. NVIDIA is constantly looking for ways to improve
    its products, so you may send feedback to NVIDIA through
    the developer portal at https://developer.nvidia.com.


1.4. No Warranties

THE SDK IS PROVIDED BY NVIDIA “AS IS” AND “WITH ALL
FAULTS.” TO THE MAXIMUM EXTENT PERMITTED BY LAW, NVIDIA AND
ITS AFFILIATES EXPRESSLY DISCLAIM ALL WARRANTIES OF ANY KIND
OR NATURE, WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING,
BUT NOT LIMITED TO, ANY WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, OR THE
ABSENCE OF ANY DEFECTS THEREIN, WHETHER LATENT OR PATENT. NO
WARRANTY IS MADE ON THE BASIS OF TRADE USAGE, COURSE OF
DEALING OR COURSE OF TRADE.


1.5. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY LAW, NVIDIA AND ITS
AFFILIATES SHALL NOT BE LIABLE FOR ANY (I) SPECIAL, INCIDENTAL,
PUNITIVE OR CONSEQUENTIAL DAMAGES, OR (II) DAMAGES FOR (A) ANY 
LOST PROFITS, LOSS OF USE, LOSS OF DATA OR LOSS OF GOODWILL, 
OR THE COSTS OF PROCURING SUBSTITUTE PRODUCTS, ARISING OUT OF 
OR IN CONNECTION WITH THIS AGREEMENT OR THE USE OR PERFORMANCE 
OF THE SDK, WHETHER SUCH LIABILITY ARISES FROM ANY CLAIM BASED 
UPON BREACH OF CONTRACT, BREACH OF WARRANTY, TORT (INCLUDING 
NEGLIGENCE), PRODUCT LIABILITY OR ANY OTHER CAUSE OF ACTION OR 
THEORY OF LIABILITY. IN NO EVENT WILL NVIDIA’S AND ITS AFFILIATES
TOTAL CUMULATIVE LIABILITY UNDER OR ARISING OUT OF THIS
AGREEMENT EXCEED US$10.00. THE NATURE OF THE LIABILITY OR THE
NUMBER OF CLAIMS OR SUITS SHALL NOT ENLARGE OR EXTEND THIS
LIMIT.

These exclusions and limitations of liability shall apply
regardless if NVIDIA or its affiliates have been advised of
the possibility of such damages, and regardless of whether a
remedy fails its essential purpose. These exclusions and
limitations of liability form an essential basis of the
bargain between the parties, and, absent any of these
exclusions or limitations of liability, the provisions of this
Agreement, including, without limitation, the economic terms,
would be substantially different.


1.6. Termination

  1. This Agreement will continue to apply until terminated by
    either you or NVIDIA as described below.

  2. If you want to terminate this Agreement, you may do so by
    stopping to use the SDK.

  3. NVIDIA may, at any time, terminate this Agreement if:

      a. (i) you fail to comply with any term of this
        Agreement and the non-compliance is not fixed within
        thirty (30) days following notice from NVIDIA (or
        immediately if you violate NVIDIA’s intellectual
        property rights);

      b. (ii) you commence or participate in any legal
        proceeding against NVIDIA with respect to the SDK; or

      c. (iii) NVIDIA decides to no longer provide the SDK in
        a country or, in NVIDIA’s sole discretion, the
        continued use of it is no longer commercially viable.

  4. Upon any termination of this Agreement, you agree to
    promptly discontinue use of the SDK and destroy all copies
    in your possession or control. Your prior distributions in
    accordance with this Agreement are not affected by the
    termination of this Agreement. Upon written request, you
    will certify in writing that you have complied with your
    commitments under this section. Upon any termination of
    this Agreement all provisions survive except for the
    license grant provisions.


1.7. General

If you wish to assign this Agreement or your rights and
obligations, including by merger, consolidation, dissolution
or operation of law, contact NVIDIA to ask for permission. Any
attempted assignment not approved by NVIDIA in writing shall
be void and of no effect. NVIDIA may assign, delegate or
transfer this Agreement and its rights and obligations, and if
to a non-affiliate you will be notified.

You agree to cooperate with NVIDIA and provide reasonably
requested information to verify your compliance with this
Agreement.

This Agreement will be governed in all respects by the laws of
the United States and of the State of Delaware, without regard to the
conflicts of laws principles. The United Nations Convention on
Contracts for the International Sale of Goods is specifically
disclaimed. You agree to all terms of this Agreement in the
English language.

The state or federal courts residing in Santa Clara County,
California shall have exclusive jurisdiction over any dispute
or claim arising out of this Agreement. Notwithstanding this,
you agree that NVIDIA shall still be allowed to apply for
injunctive remedies or an equivalent type of urgent legal
relief in any jurisdiction.

If any court of competent jurisdiction determines that any
provision of this Agreement is illegal, invalid or
unenforceable, such provision will be construed as limited to
the extent necessary to be consistent with and fully
enforceable under the law and the remaining provisions will
remain in full force and effect. Unless otherwise specified,
remedies are cumulative.

Each party acknowledges and agrees that the other is an
independent contractor in the performance of this Agreement.

The SDK has been developed entirely at private expense and is
“commercial items” consisting of “commercial computer
software” and “commercial computer software
documentation” provided with RESTRICTED RIGHTS. Use,
duplication or disclosure by the U.S. Government or a U.S.
Government subcontractor is subject to the restrictions in
this Agreement pursuant to DFARS 227.7202-3(a) or as set forth
in subparagraphs (c)(1) and (2) of the Commercial Computer
Software - Restricted Rights clause at FAR 52.227-19, as
applicable. Contractor/manufacturer is NVIDIA, 2788 San Tomas
Expressway, Santa Clara, CA 95051.

The SDK is subject to United States export laws and
regulations. You agree that you will not ship, transfer or
export the SDK into any country, or use the SDK in any manner,
prohibited by the United States Bureau of Industry and
Security or economic sanctions regulations administered by the
U.S. Department of Treasury’s Office of Foreign Assets
Control (OFAC), or any applicable export laws, restrictions or
regulations. These laws include restrictions on destinations,
end users and end use. By accepting this Agreement, you
confirm that you are not located in a country currently 
embargoed by the U.S. or otherwise prohibited from receiving 
the SDK under U.S. law.

Any notice delivered by NVIDIA to you under this Agreement
will be delivered via mail, email or fax. You agree that any
notices that NVIDIA sends you electronically will satisfy any
legal communication requirements. Please direct your legal
notices or other correspondence to NVIDIA Corporation, 2788
San Tomas Expressway, Santa Clara, California 95051, United
States of America, Attention: Legal Department.

This Agreement and any exhibits incorporated into this
Agreement constitute the entire agreement of the parties with
respect to the subject matter of this Agreement and supersede
all prior negotiations or documentation exchanged between the
parties relating to this SDK license. Any additional and/or
conflicting terms on documents issued by you are null, void,
and invalid. Any amendment or waiver under this Agreement
shall be in writing and signed by representatives of both
parties.


2. CUDA Toolkit Supplement to Software License Agreement for
NVIDIA Software Development Kits
------------------------------------------------------------

The terms in this supplement govern your use of the NVIDIA
CUDA Toolkit SDK under the terms of your license agreement
(“Agreement”) as modified by this supplement. Capitalized
terms used but not defined below have the meaning assigned to
them in the Agreement.

This supplement is an exhibit to the Agreement and is
incorporated as an integral part of the Agreement. In the
event of conflict between the terms in this supplement and the
terms in the Agreement, the terms in this supplement govern.


2.1. License Scope

The SDK is licensed for you to develop applications only for
use in systems with NVIDIA GPUs.


2.2. Distribution

The portions of the SDK that are distributable under the
Agreement are listed in Attachment A.


2.3. Operating Systems

Those portions of the SDK designed exclusively for use on the
Linux or FreeBSD operating systems, or other operating systems
derived from the source code to these operating systems, may
be copied and redistributed for use in accordance with this
Agreement, provided that the object code files are not
modified in any way (except for unzipping of compressed
files).


2.4. Audio and Video Encoders and Decoders

You acknowledge and agree that it is your sole responsibility
to obtain any additional third-party licenses required to
make, have made, use, have used, sell, import, and offer for
sale your products or services that include or incorporate any
third-party software and content relating to audio and/or
video encoders and decoders from, including but not limited
to, Microsoft, Thomson, Fraunhofer IIS, Sisvel S.p.A.,
MPEG-LA, and Coding Technologies. NVIDIA does not grant to you
under this Agreement any necessary patent or other rights with
respect to any audio and/or video encoders and decoders.


2.5. Licensing

If the distribution terms in this Agreement are not suitable
for your organization, or for any questions regarding this
Agreement, please contact NVIDIA at
nvidia-compute-license-questions@nvidia.com.
```

### 2.6. Attachment A — Redistributable CUDA Toolkit Components

The following CUDA Toolkit files may be distributed with
applications developed by you, including certain
variations of these files that have version number or
architecture specific information embedded in the file name -
as an example only, for release version 9.0 of the 64-bit
Windows software, the file cudart64_90.dll is redistributable.

| Component | Windows | Mac OSX | Linux | Android | All |
| --- | --- | --- | --- | --- | --- |
| CUDA Runtime | cudart.dll, cudart_static.lib, cudadevrt.lib | libcudart.dylib, libcudart_static.a, libcudadevrt.a | libcudart.so, libcudart_static.a, libcudadevrt.a | libcudart.so, libcudart_static.a, libcudadevrt.a | — |
| CUDA FFT Library | cufft.dll, cufftw.dll, cufft.lib, cufftw.lib | libcufft.dylib, libcufft_static.a, libcufftw.dylib, libcufftw_static.a | libcufft.so, libcufft_static.a, libcufftw.so, libcufftw_static.a | libcufft.so, libcufft_static.a, libcufftw.so, libcufftw_static.a | — |
| CUDA BLAS Library | cublas.dll, cublasLt.dll | libcublas.dylib, libcublasLt.dylib, libcublas_static.a, libcublasLt_static.a | libcublas.so, libcublasLt.so, libcublas_static.a, libcublasLt_static.a | libcublas.so, libcublasLt.so, libcublas_static.a, libcublasLt_static.a | — |
| NVIDIA "Drop-in" BLAS Library | nvblas.dll | libnvblas.dylib | libnvblas.so | — | — |
| CUDA Sparse Matrix Library | cusparse.dll, cusparse.lib | libcusparse.dylib, libcusparse_static.a | libcusparse.so, libcusparse_static.a | libcusparse.so, libcusparse_static.a | — |
| CUDA Linear Solver Library | cusolver.dll, cusolver.lib | libcusolver.dylib, libcusolver_static.a | libcusolver.so, libcusolver_static.a | libcusolver.so, libcusolver_static.a | — |
| CUDA Random Number Generation Library | curand.dll, curand.lib | libcurand.dylib, libcurand_static.a | libcurand.so, libcurand_static.a | libcurand.so, libcurand_static.a | — |
| NVIDIA Performance Primitives Library | nppc.dll, nppc.lib, nppial.dll, nppial.lib, nppicc.dll, nppicc.lib, nppicom.dll, nppicom.lib, nppidei.dll, nppidei.lib, nppif.dll, nppif.lib, nppig.dll, nppig.lib, nppim.dll, nppim.lib, nppist.dll, nppist.lib, nppisu.dll, nppisu.lib, nppitc.dll, nppitc.lib, npps.dll, npps.lib | libnppc.dylib, libnppc_static.a, libnppial.dylib, libnppial_static.a, libnppicc.dylib, libnppicc_static.a, libnppicom.dylib, libnppicom_static.a, libnppidei.dylib, libnppidei_static.a, libnppif.dylib, libnppif_static.a, libnppig.dylib, libnppig_static.a, libnppim.dylib, libnppisu_static.a, libnppitc.dylib, libnppitc_static.a, libnpps.dylib, libnpps_static.a | libnppc.so, libnppc_static.a, libnppial.so, libnppial_static.a, libnppicc.so, libnppicc_static.a, libnppicom.so, libnppicom_static.a, libnppidei.so, libnppidei_static.a, libnppif.so, libnppif_static.a libnppig.so, libnppig_static.a, libnppim.so, libnppim_static.a, libnppist.so, libnppist_static.a, libnppisu.so, libnppisu_static.a, libnppitc.so libnppitc_static.a, libnpps.so, libnpps_static.a | libnppc.so, libnppc_static.a, libnppial.so, libnppial_static.a, libnppicc.so, libnppicc_static.a, libnppicom.so, libnppicom_static.a, libnppidei.so, libnppidei_static.a, libnppif.so, libnppif_static.a libnppig.so, libnppig_static.a, libnppim.so, libnppim_static.a, libnppist.so, libnppist_static.a, libnppisu.so, libnppisu_static.a, libnppitc.so libnppitc_static.a, libnpps.so, libnpps_static.a | — |
| NVIDIA JPEG Library | nvjpeg.lib, nvjpeg.dll | — | libnvjpeg.so, libnvjpeg_static.a | — | — |
| Internal common library required for statically linking to cuBLAS, cuSPARSE, cuFFT, cuRAND, nvJPEG and NPP | — | libculibos.a | libculibos.a | — | — |
| NVIDIA Runtime Compilation Library and Header | nvrtc.dll, nvrtc-builtins.dll | libnvrtc.dylib, libnvrtc-builtins.dylib | libnvrtc.so, libnvrtc-builtins.so, libnvrtc_static.a, libnvrtx-builtins_static.a | — | nvrtc.h |
| NVIDIA Optimizing Compiler Library | nvvm.dll | libnvvm.dylib | libnvvm.so | — | — |
| NVIDIA JIT Linking Library | libnvJitLink.dll, libnvJitLink.lib | — | libnvJitLink.so, libnvJitLink_static.a | — | — |
| NVIDIA Common Device Math Functions Library | libdevice.10.bc | libdevice.10.bc | libdevice.10.bc | — | — |
| CUDA Occupancy Calculation Header Library | — | — | — | — | cuda_occupancy.h |
| CUDA Floating Point Type Headers | — | — | — | — | cuda_fp16.h, cuda_fp16.hpp, cuda_bf16.h, cuda_bf16.hpp, cuda_fp8.h, cuda_fp8.hpp, cuda_fp6.h, cuda_fp6.hpp, cuda_fp4.h, cuda_fp4.hpp |
| CUDA Headers for Runtime Compilation | — | — | — | — | crt/host_defines.h, cuComplex.h, cuda_awbarrier_helpers.h, cuda_awbarrier_primitives.h, cuda_awbarrier.h, cuda_pipeline_helpers.h, ccuda_pipeline_primitives.h, ccuda_pipeline.h, cuda_runtime_api.h, cuda.h, cuda/std/tuple, cuda/std/type_traits, cuda/std/type_traits, cuda/std/utility, device_types.h, vector_functions.h, vector_types.h |
| CUDA Profiling Tools Interface (CUPTI) Library | cupti.dll | libcupti.dylib | libcupti.so | — | — |
| NVIDIA Tools Extension Library | nvToolsExt.dll, nvToolsExt.lib | libnvToolsExt.dylib | libnvToolsExt.so | — | — |
| NVIDIA CUDA Driver Libraries | — | — | libcuda.so, libnvidia-ptxjitcompiler.so, libnvptxcompiler_static.a | — | — |
| NVIDIA CUDA File IO Libraries and Header | — | — | libcufile.so, libcufile_rdma.so, libcufile_static.a, libcufile_rdma_static.a | — | cufile.h |

```text
In addition to the rights above, for parties that are
developing software intended solely for use on Jetson
development kits or Jetson modules, and running Linux for
Tegra software, the following shall apply:

  * The SDK may be distributed in its entirety, as provided by
    NVIDIA, and without separation of its components, for you
    and/or your licensees to create software development kits
    for use only on the Jetson platform and running Linux for
    Tegra software.
```

### 2.7. Attachment B

```text



Additional Licensing Obligations

The following third party components included in the SOFTWARE
are licensed to Licensee pursuant to the following terms and
conditions:

  1. Licensee's use of the GDB third party component is
    subject to the terms and conditions of GNU GPL v3:

    This product includes copyrighted third-party software licensed
    under the terms of the GNU General Public License v3 ("GPL v3").
    All third-party software packages are copyright by their respective
    authors. GPL v3 terms and conditions are hereby incorporated into
    the Agreement by this reference:     http://www.gnu.org/licenses/gpl.txt

    Consistent with these licensing requirements, the software
    listed below is provided under the terms of the specified
    open source software licenses. To obtain source code for
    software provided under licenses that require
    redistribution of source code, including the GNU General
    Public License (GPL) and GNU Lesser General Public License
    (LGPL), contact oss-requests@nvidia.com. This offer is
    valid for a period of three (3) years from the date of the
    distribution of this product by NVIDIA CORPORATION.

    Component          License
    CUDA-GDB           GPL v3  

  2. Licensee represents and warrants that any and all third
    party licensing and/or royalty payment obligations in
    connection with Licensee's use of the H.264 video codecs
    are solely the responsibility of Licensee.

  3. Licensee's use of the Thrust library is subject to the
    terms and conditions of the Apache License Version 2.0.
    All third-party software packages are copyright by their
    respective authors. Apache License Version 2.0 terms and
    conditions are hereby incorporated into the Agreement by
    this reference.
    http://www.apache.org/licenses/LICENSE-2.0.html

    In addition, Licensee acknowledges the following notice:
    Thrust includes source code from the Boost Iterator,
    Tuple, System, and Random Number libraries.

    Boost Software License - Version 1.0 - August 17th, 2003
    . . . .
    
    Permission is hereby granted, free of charge, to any person or 
    organization obtaining a copy of the software and accompanying 
    documentation covered by this license (the "Software") to use, 
    reproduce, display, distribute, execute, and transmit the Software, 
    and to prepare derivative works of the Software, and to permit 
    third-parties to whom the Software is furnished to do so, all 
    subject to the following:
    
    The copyright notices in the Software and this entire statement, 
    including the above license grant, this restriction and the following 
    disclaimer, must be included in all copies of the Software, in whole 
    or in part, and all derivative works of the Software, unless such 
    copies or derivative works are solely in the form of machine-executable 
    object code generated by a source language processor.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND 
    NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR 
    ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR 
    OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, ARISING 
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
    OTHER DEALINGS IN THE SOFTWARE.  

  4. Licensee's use of the LLVM third party component is
    subject to the following terms and conditions:

    ======================================================
    LLVM Release License
    ======================================================
    University of Illinois/NCSA
    Open Source License
    
    Copyright (c) 2003-2010 University of Illinois at Urbana-Champaign.
    All rights reserved.
    
    Developed by:
    
        LLVM Team
    
        University of Illinois at Urbana-Champaign
    
        http://llvm.org
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to 
    deal with the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
    sell copies of the Software, and to permit persons to whom the Software is 
    furnished to do so, subject to the following conditions:
    
    *  Redistributions of source code must retain the above copyright notice, 
       this list of conditions and the following disclaimers.
    
    *  Redistributions in binary form must reproduce the above copyright 
       notice, this list of conditions and the following disclaimers in the 
       documentation and/or other materials provided with the distribution.
    
    *  Neither the names of the LLVM Team, University of Illinois at Urbana-
       Champaign, nor the names of its contributors may be used to endorse or
       promote products derived from this Software without specific prior 
       written permission.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL 
    THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS WITH THE SOFTWARE.  

  5. Licensee's use of the PCRE third party component is
    subject to the following terms and conditions:

    ------------
    PCRE LICENCE
    ------------
    PCRE is a library of functions to support regular expressions whose syntax
    and semantics are as close as possible to those of the Perl 5 language.
    Release 8 of PCRE is distributed under the terms of the "BSD" licence, as
    specified below. The documentation for PCRE, supplied in the "doc" 
    directory, is distributed under the same terms as the software itself. The
    basic library functions are written in C and are freestanding. Also 
    included in the distribution is a set of C++ wrapper functions, and a just-
    in-time compiler that can be used to optimize pattern matching. These are 
    both optional features that can be omitted when the library is built.
    
    THE BASIC LIBRARY FUNCTIONS
    ---------------------------
    Written by:       Philip Hazel
    Email local part: ph10
    Email domain:     cam.ac.uk
    University of Cambridge Computing Service,
    Cambridge, England.
    Copyright (c) 1997-2012 University of Cambridge
    All rights reserved.
    
    PCRE JUST-IN-TIME COMPILATION SUPPORT
    -------------------------------------
    Written by:       Zoltan Herczeg
    Email local part: hzmester
    Emain domain:     freemail.hu
    Copyright(c) 2010-2012 Zoltan Herczeg
    All rights reserved.
    
    STACK-LESS JUST-IN-TIME COMPILER
    --------------------------------
    Written by:       Zoltan Herczeg
    Email local part: hzmester
    Emain domain:     freemail.hu
    Copyright(c) 2009-2012 Zoltan Herczeg
    All rights reserved.
    
    THE C++ WRAPPER FUNCTIONS
    -------------------------
    Contributed by:   Google Inc.
    Copyright (c) 2007-2012, Google Inc.
    All rights reserved.

    THE "BSD" LICENCE
    -----------------
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
      * Redistributions of source code must retain the above copyright notice, 
        this list of conditions and the following disclaimer.
    
      * Redistributions in binary form must reproduce the above copyright 
        notice, this list of conditions and the following disclaimer in the 
        documentation and/or other materials provided with the distribution.
    
      * Neither the name of the University of Cambridge nor the name of Google 
        Inc. nor the names of their contributors may be used to endorse or 
        promote products derived from this software without specific prior 
        written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.  

  6. Some of the cuBLAS library routines were written by or
    derived from code written by Vasily Volkov and are subject
    to the Modified Berkeley Software Distribution License as
    follows:

    Copyright (c) 2007-2009, Regents of the University of California
    
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.
        * Neither the name of the University of California, Berkeley nor
          the names of its contributors may be used to endorse or promote
          products derived from this software without specific prior
          written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
    STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.  

  7. Some of the cuBLAS library routines were written by or
    derived from code written by Davide Barbieri and are
    subject to the Modified Berkeley Software Distribution
    License as follows:

    Copyright (c) 2008-2009 Davide Barbieri @ University of Rome Tor Vergata.
    
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.
        * The name of the author may not be used to endorse or promote
          products derived from this software without specific prior
          written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
    STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.  

  8. Some of the cuBLAS library routines were derived from
    code developed by the University of Tennessee and are
    subject to the Modified Berkeley Software Distribution
    License as follows:

    Copyright (c) 2010 The University of Tennessee.
    
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer listed in this license in the documentation and/or
          other materials provided with the distribution.
        * Neither the name of the copyright holders nor the names of its
          contributors may be used to endorse or promote products derived
          from this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  9. Some of the cuBLAS library routines were written by or
    derived from code written by Jonathan Hogg and are subject
    to the Modified Berkeley Software Distribution License as
    follows:

    Copyright (c) 2012, The Science and Technology Facilities Council (STFC).
    
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.
        * Neither the name of the STFC nor the names of its contributors
          may be used to endorse or promote products derived from this
          software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE STFC BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
    BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
    IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  10. Some of the cuBLAS library routines were written by or
    derived from code written by Ahmad M. Abdelfattah, David
    Keyes, and Hatem Ltaief, and are subject to the Apache
    License, Version 2.0, as follows:

     -- (C) Copyright 2013 King Abdullah University of Science and Technology
      Authors:
      Ahmad Abdelfattah (ahmad.ahmad@kaust.edu.sa)
      David Keyes (david.keyes@kaust.edu.sa)
      Hatem Ltaief (hatem.ltaief@kaust.edu.sa)
    
      Redistribution  and  use  in  source and binary forms, with or without
      modification,  are  permitted  provided  that the following conditions
      are met:
    
      * Redistributions  of  source  code  must  retain  the above copyright
        notice,  this  list  of  conditions  and  the  following  disclaimer.
      * Redistributions  in  binary  form must reproduce the above copyright
        notice,  this list of conditions and the following disclaimer in the
        documentation  and/or other materials provided with the distribution.
      * Neither  the  name of the King Abdullah University of Science and
        Technology nor the names of its contributors may be used to endorse 
        or promote products derived from this software without specific prior 
        written permission.
    
      THIS  SOFTWARE  IS  PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
      ``AS IS''  AND  ANY  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
      LIMITED  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
      A  PARTICULAR  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
      HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
      SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT NOT
      LIMITED  TO,  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
      DATA,  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY  OF  LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
      (INCLUDING  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
      OF  THIS  SOFTWARE,  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE  

  11. Some of the cuSPARSE library routines were written by or
    derived from code written by Li-Wen Chang and are subject
    to the NCSA Open Source License as follows:

    Copyright (c) 2012, University of Illinois.
    
    All rights reserved.
    
    Developed by: IMPACT Group, University of Illinois, http://impact.crhc.illinois.edu
    
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal with the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimers in the documentation and/or other materials provided
          with the distribution.
        * Neither the names of IMPACT Group, University of Illinois, nor
          the names of its contributors may be used to endorse or promote
          products derived from this Software without specific prior
          written permission.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
    IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE
    SOFTWARE.  

  12. Some of the cuRAND library routines were written by or
    derived from code written by Mutsuo Saito and Makoto
    Matsumoto and are subject to the following license:

    Copyright (c) 2009, 2010 Mutsuo Saito, Makoto Matsumoto and Hiroshima
    University. All rights reserved.
    
    Copyright (c) 2011 Mutsuo Saito, Makoto Matsumoto, Hiroshima
    University and University of Tokyo.  All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.
        * Neither the name of the Hiroshima University nor the names of
          its contributors may be used to endorse or promote products
          derived from this software without specific prior written
          permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  13. Some of the cuRAND library routines were derived from
    code developed by D. E. Shaw Research and are subject to
    the following license:

    Copyright 2010-2011, D. E. Shaw Research.
    
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions, and the following disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions, and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution.
        * Neither the name of D. E. Shaw Research nor the names of its
          contributors may be used to endorse or promote products derived
          from this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  14. Some of the Math library routines were written by or
    derived from code developed by Norbert Juffa and are
    subject to the following license:

    Copyright (c) 2015-2017, Norbert Juffa
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without 
    modification, are permitted provided that the following conditions
    are met:
    
    1. Redistributions of source code must retain the above copyright 
       notice, this list of conditions and the following disclaimer.
    
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  15. Licensee's use of the lz4 third party component is
    subject to the following terms and conditions:

    Copyright (C) 2011-2013, Yann Collet.
    BSD 2-Clause License (http://www.opensource.org/licenses/bsd-license.php)
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
    
        * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following disclaimer
    in the documentation and/or other materials provided with the
    distribution.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

  16. The NPP library uses code from the Boost Math Toolkit,
    and is subject to the following license:

    Boost Software License - Version 1.0 - August 17th, 2003
    . . . .
    
    Permission is hereby granted, free of charge, to any person or 
    organization obtaining a copy of the software and accompanying 
    documentation covered by this license (the "Software") to use, 
    reproduce, display, distribute, execute, and transmit the Software, 
    and to prepare derivative works of the Software, and to permit 
    third-parties to whom the Software is furnished to do so, all 
    subject to the following:
    
    The copyright notices in the Software and this entire statement, 
    including the above license grant, this restriction and the following 
    disclaimer, must be included in all copies of the Software, in whole 
    or in part, and all derivative works of the Software, unless such 
    copies or derivative works are solely in the form of machine-executable 
    object code generated by a source language processor.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND 
    NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR 
    ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR 
    OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, ARISING 
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
    OTHER DEALINGS IN THE SOFTWARE.  

  17. Portions of the Nsight Eclipse Edition is subject to the
    following license:

    The Eclipse Foundation makes available all content in this plug-in
    ("Content"). Unless otherwise indicated below, the Content is provided
    to you under the terms and conditions of the Eclipse Public License
    Version 1.0 ("EPL"). A copy of the EPL is available at http://
    www.eclipse.org/legal/epl-v10.html. For purposes of the EPL, "Program"
    will mean the Content.
    
    If you did not receive this Content directly from the Eclipse
    Foundation, the Content is being redistributed by another party
    ("Redistributor") and different terms and conditions may apply to your
    use of any object code in the Content. Check the Redistributor's
    license that was provided with the Content. If no such license exists,
    contact the Redistributor. Unless otherwise indicated below, the terms
    and conditions of the EPL still apply to any source code in the
    Content and such source code may be obtained at http://www.eclipse.org.  

  18. Some of the cuBLAS library routines uses code from
    OpenAI, which is subject to the following license:

    License URL 
    https://github.com/openai/openai-gemm/blob/master/LICENSE
    
    License Text 
    The MIT License
    
    Copyright (c) 2016 OpenAI (http://openai.com), 2016 Google Inc.
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.   

  19. Licensee's use of the Visual Studio Setup Configuration
    Samples is subject to the following license:

    The MIT License (MIT) 
    Copyright (C) Microsoft Corporation. All rights reserved.
    
    Permission is hereby granted, free of charge, to any person 
    obtaining a copy of this software and associated documentation 
    files (the "Software"), to deal in the Software without restriction, 
    including without limitation the rights to use, copy, modify, merge, 
    publish, distribute, sublicense, and/or sell copies of the Software, 
    and to permit persons to whom the Software is furnished to do so, 
    subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included 
    in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  

 20. Licensee's use of linmath.h header for CPU functions for
     GL vector/matrix operations from lunarG is subject to the
     Apache License Version 2.0.

 21. The DX12-CUDA sample uses the d3dx12.h header, which is
     subject to the MIT license.

 22. Components of the driver and compiler used for binary management, including 
      nvFatBin, nvcc, and cuobjdump, use the Zstandard library which is subject to
      the following license:

      BSD License

      For Zstandard software

      Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.

      Redistribution and use in source and binary forms, with or without modification,
      are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name Facebook, nor Meta, nor the names of its contributors may
          be used to endorse or promote products derived from this software without
          specific prior written permission.

     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
     ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
     DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
     OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
     WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
     ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
     OF SUCH DAMAGE.


  23. Portions of support for math operations on 128-bit floating-point data type in compiler
      were derived from SLEEF library which is subject to the following license:

     Boost Software License - Version 1.0 - August 17th, 2003

    Permission is hereby granted, free of charge, to any person or organization
    obtaining a copy of the software and accompanying documentation covered by
    this license (the "Software") to use, reproduce, display, distribute,
    execute, and transmit the Software, and to prepare derivative works of the
    Software, and to permit third-parties to whom the Software is furnished to
    do so, all subject to the following:

    The copyright notices in the Software and this entire statement, including
    the above license grant, this restriction and the following disclaimer,
    must be included in all copies of the Software, in whole or in part, and
    all derivative works of the Software, unless such copies or derivative
    works are solely in the form of machine-executable object code generated by
    a source language processor.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
    SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
    FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
   
 24. Portions of support for math operations on 128-bit floating-point data type
     in compiler were derived from SoftFloat library which is subject to the following license:

    The SoftFloat package was written by me, John R. Hauser. Release 3 of SoftFloat
    was a completely new implementation supplanting earlier releases. The project to
    create Release 3 (now through 3e) was done in the employ of the University of
    California, Berkeley, within the Department of Electrical Engineering and
    Computer Sciences, first for the Parallel Computing Laboratory (Par Lab) and
    then for the ASPIRE Lab. The work was officially overseen by Prof. Krste
    Asanovic, with funding provided by these sources:

    Par Lab: Microsoft (Award #024263), Intel (Award #024894), and U.C. Discovery
    (Award #DIG07-10227), with additional support from Par Lab affiliates Nokia,
    NVIDIA, Oracle, and Samsung.
    ASPIRE Lab: DARPA PERFECT program (Award #HR0011-12-2-0016), with additional
    support from ASPIRE industrial sponsor Intel and ASPIRE affiliates Google, Nokia,
    NVIDIA, Oracle, and Samsung.
    The following applies to the whole of SoftFloat Release 3e as well as to each
    source file individually.

    Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 The Regents of the
    University of California. All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions, and the following disclaimer in the documentation and/or
    other materials provided with the distribution.

    Neither the name of the University nor the names of its contributors may be used
    to endorse or promote products derived from this software without specific prior
    written permission.

    THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY EXPRESS
    OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE DISCLAIMED. IN NO EVENT
    SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
    BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.
-----------------
```

---

## NVIDIA Fabric Manager (grouped with 2 other entries sharing this license)

**Entries covered by the license text below:**

- **NVIDIA Fabric Manager; version 580.126.20 (matches Nvidia Driver; 550.127.08 on AL2)** — <https://docs.nvidia.com/datacenter/tesla/fabric-manager-user-guide/>
- **NVIDIA IMEX; version 580.126.20 (matches Nvidia Driver; 550.127.08 on AL2)** — <https://docs.nvidia.com/multi-node-nvlink-systems/imex-guide/>
- **NVIDIA NVLSM; version 2025.03.9-1** — <https://docs.nvidia.com/networking/display/mlnxofedv461000/nvidia+subnet+manager>

```text

    * Package NVIDIA Fabric Manager's source/binary may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/dependencies/nvidia_fabric/

    * Package NVIDIA IMEX's source/binary may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/dependencies/nvidia_imex/

    * Package NVIDIA NVLSM's source/binary may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/dependencies/nvidia_nvlsm/

The nvidia-fabricmanager, nvidia-imex, and nvlsm packages are installed
from NVIDIA-signed RPMs. Each carries its own LICENSE file at
/usr/share/licenses/<package>/LICENSE on the built ParallelCluster AMI.
The three LICENSE files share the same legal text (the "License For
Customer Use of NVIDIA Software" template), reproduced once below.
Each package also ships its own third-party-notices file listing the
third-party components it bundles; those notices are reproduced
separately after the shared LICENSE.

           License For Customer Use of NVIDIA Software


IMPORTANT NOTICE -- READ CAREFULLY: This License For Customer Use of
NVIDIA Software ("LICENSE") is the agreement which governs use of
the software of NVIDIA Corporation and its subsidiaries ("NVIDIA")
downloadable herefrom, including computer software and associated
printed materials ("SOFTWARE").  By downloading, installing, copying,
or otherwise using the SOFTWARE, you agree to be bound by the terms
of this LICENSE.  If you do not agree to the terms of this LICENSE,
do not download the SOFTWARE.

RECITALS

Use of NVIDIA's products requires three elements: the SOFTWARE, the
hardware on a graphics controller board, and a personal computer. The
SOFTWARE is protected by copyright laws and international copyright
treaties, as well as other intellectual property laws and treaties.
The SOFTWARE is not sold, and instead is only licensed for use,
strictly in accordance with this document.  The hardware is protected
by various patents, and is sold, but this agreement does not cover
that sale, since it may not necessarily be sold as a package with
the SOFTWARE.  This agreement sets forth the terms and conditions
of the SOFTWARE LICENSE only.

1.  DEFINITIONS

1.1  Customer.  Customer means the entity or individual that
downloads the SOFTWARE.

2.  GRANT OF LICENSE

2.1  Rights and Limitations of Grant.  NVIDIA hereby grants Customer
the following non-exclusive, non-transferable right to use the
SOFTWARE, with the following limitations:

2.1.1  Rights.  Customer may install and use multiple copies of the
SOFTWARE on a shared computer or concurrently on different computers,
and make multiple back-up copies of the SOFTWARE, solely for Customer's
use within Customer's Enterprise. "Enterprise" shall mean individual use
by Customer or any legal entity (such as a corporation or university)
and the subsidiaries it owns by more than fifty percent (50%).

2.1.2  Linux/FreeBSD Exception.  Notwithstanding the foregoing terms
of Section 2.1.1, SOFTWARE designed exclusively for use on the Linux or
FreeBSD operating systems, or other operating systems derived from the
source code to these operating systems, may be copied and redistributed,
provided that the binary files thereof are not modified in any way
(except for unzipping of compressed files).

2.1.3  Limitations.

No Reverse Engineering.  Customer may not reverse engineer,
decompile, or disassemble the SOFTWARE, nor attempt in any other
manner to obtain the source code.

No Separation of Components.  The SOFTWARE is licensed as a
single product.  Its component parts may not be separated for use
on more than one computer, nor otherwise used separately from the
other parts.

No Rental.  Customer may not rent or lease the SOFTWARE to someone
else.

3.  TERMINATION

This LICENSE will automatically terminate if Customer fails to
comply with any of the terms and conditions hereof.  In such event,
Customer must destroy all copies of the SOFTWARE and all of its
component parts.

Defensive Suspension.  If Customer commences or participates in any legal
proceeding against NVIDIA, then NVIDIA may, in its sole discretion,
suspend or terminate all license grants and any other rights provided
under this LICENSE during the pendency of such legal proceedings.

4.  COPYRIGHT

All title and copyrights in and to the SOFTWARE (including but
not limited to all images, photographs, animations, video, audio,
music, text, and other information incorporated into the SOFTWARE),
the accompanying printed materials, and any copies of the SOFTWARE,
are owned by NVIDIA, or its suppliers.  The SOFTWARE is protected
by copyright laws and international treaty provisions.  Accordingly,
Customer is required to treat the SOFTWARE like any other copyrighted
material, except as otherwise allowed pursuant to this LICENSE
and that it may make one copy of the SOFTWARE solely for backup or
archive purposes.

5.  APPLICABLE LAW

This agreement shall be deemed to have been made in, and shall be
construed pursuant to, the laws of the State of California.

6.  DISCLAIMER OF WARRANTIES AND LIMITATION ON LIABILITY

6.1  No Warranties.  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
LAW, THE SOFTWARE IS PROVIDED "AS IS" AND NVIDIA AND ITS SUPPLIERS
DISCLAIM ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT
NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE.

6.2  No Liability for Consequential Damages.  TO THE MAXIMUM
EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL NVIDIA OR
ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR
CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION,
DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS
OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT
OF THE USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF NVIDIA HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

6.3  Specific Use.  SOFTWARE is licensed only for use with NVIDIA products.
Customer's use of NVIDIA products with any other firmware is at its own
risk and may cause an NVIDIA product to become non-compliant with certain
of its certification markings.

7.  MISCELLANEOUS

The United Nations Convention on Contracts for the International
Sale of Goods is specifically disclaimed.  If any provision of this
LICENSE is inconsistent with, or cannot be fully enforced under,
the law, such provision will be construed as limited to the extent
necessary to be consistent with and fully enforceable under the law.
This agreement is the final, complete and exclusive agreement between
the parties relating to the subject matter hereof, and supersedes
all prior or contemporaneous understandings and agreements relating
to such subject matter, whether oral or written.  Customer agrees
that it will not ship, transfer or export the SOFTWARE into any
country, or use the SOFTWARE in any manner, prohibited by the
United States Bureau of Export Administration or any export laws,
restrictions or regulations.  This LICENSE may only be modified in
writing signed by an authorized officer of NVIDIA.

Third-Party Components Bundled in NVIDIA Fabric Manager
-------------------------------------------------------
Source: /usr/share/licenses/nvidia-fabricmanager/third-party-notices.txt

This Third Party Notices file provides notices and information about third
party components included in the SOFTWARE. The following third party
components are licensed to Licensee pursuant to the following terms and conditions:

1. Licensee's use of Google Protobuffers 3.20.1 is subject to the terms and conditions of the
3-clause BSD License. All third-party software packages are copyright by their
respective authors. The 3-clause BSD License terms and conditions are hereby
incorporated into the Agreement by this reference. https://github.com/protocolbuffers/protobuf/blob/main/LICENSE

2. Licensee's use of libevent 2.0.22 is subject to the terms and conditions of the
3-clause BSD License. All third-party software packages are copyright by their
respective authors. The 3-clause BSD License terms and conditions are hereby
incorporated into the Agreement by this referece. http://libevent.org/LICENSE.txt

==============================
Copyright (c) 2000-2007 Niels Provos <provos@citi.umich.edu>
Copyright (c) 2007-2010 Niels Provos and Nick Mathewson

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


3. Licensee's use of the Multi-Threaded Libevent Server Example is subject to
the terms and conditions of the BSD License. All third-party software packages
are copyright by their respective authors. The BSD License terms and conditions are hereby
incorporated into the Agreement by this referece.
http://sourceforge.net/projects/libevent-thread/files/?source=navbar

Copyright (c) 2012, Ronald B. Cemer
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer. Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and
the following disclaimer in the documentation and/or other materials provided
with the distribution. Neither the name of Ronald B. Cemer nor the names of
its contributors may be used to endorse or promote products derived from this
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

4. Licensee's use of OpenSSL 3.x is subject to the terms and conditions of the Apache License 2.0.
All third party software packages are copyright by their respective authors. The Apache License 2.0
terms and conditions are hereby incorporated into the Agreement by this reference.
https://www.openssl.org/source/apache-license-2.0.txt

5. Licensee's use of gRPC 1.45 is subject to the terms and conditions of the
Apache License 2.0, 3-clause BSD License and Mozilla Public License Version 2.0.
All third-party software packages are copyright by their
respective authors. The Apache License 2.0, 3-clause BSD License
and Mozilla Public License Version 2.0 terms and conditions are hereby
incorporated into the Agreement by this referece. https://github.com/grpc/grpc/blob/master/LICENSE
(The Apache-2.0, BSD-3-Clause, and MPL-2.0 full license texts are reproduced
in full earlier in this document and in the MySQL block's Standard Licenses
section; they are not duplicated here. The gRPC-specific copyright header is:)

==============================
Copyright 2008 Google Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
    * Neither the name of Google Inc. nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Code generated by the Protocol Buffer compiler is owned by the owner
of the input file used when generating it.  This code is not
standalone and requires a support library to be linked with it.  This
support library is itself covered by the above license.
==============================

6. Licensee's use of lmdb is subject to the terms and conditions of the
OpenLDAP Public License. All third-party software packages are copyright by their
respective authors. The OpenLDAP Public License terms and conditions are hereby
incorporated into the Agreement by this reference.
https://github.com/LMDB/lmdb/blob/mdb.master/libraries/liblmdb/LICENSE

The OpenLDAP Public License
  Version 2.8, 17 August 2003

Redistribution and use of this software and associated documentation
("Software"), with or without modification, are permitted provided
that the following conditions are met:

1. Redistributions in source form must retain copyright statements
   and notices,

2. Redistributions in binary form must reproduce applicable copyright
   statements and notices, this list of conditions, and the following
   disclaimer in the documentation and/or other materials provided
   with the distribution, and

3. Redistributions must contain a verbatim copy of this document.

The OpenLDAP Foundation may revise this license from time to time.
Each revision is distinguished by a version number.  You may use
this Software under terms of this license revision or under the
terms of any subsequent revision of the license.

THIS SOFTWARE IS PROVIDED BY THE OPENLDAP FOUNDATION AND ITS
CONTRIBUTORS ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT
SHALL THE OPENLDAP FOUNDATION, ITS CONTRIBUTORS, OR THE AUTHOR(S)
OR OWNER(S) OF THE SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

The names of the authors and copyright holders must not be used in
advertising or otherwise to promote the sale, use or other dealing
in this Software without specific, written prior permission.  Title
to copyright in this Software shall at all times remain with copyright
holders.

OpenLDAP is a registered trademark of the OpenLDAP Foundation.

Copyright 1999-2003 The OpenLDAP Foundation, Redwood City,
California, USA.  All Rights Reserved.  Permission to copy and
distribute verbatim copies of this document is granted.

7. Licensee's use of libibumad is subject to the terms and conditions of the
OpenIB.org BSD (FreeBSD variant) License. All third-party software packages are
copyright by their respective authors. The OpenIB.org BSD (FreeBSD variant) License
terms and conditions are hereby incorporated into the Agreement by this reference.
https://github.com/linux-rdma/rdma-core/blob/master/COPYING.BSD_FB


                   OpenIB.org BSD license (FreeBSD Variant)

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Third-Party Components Bundled in NVIDIA NVLSM
----------------------------------------------
Source: /usr/share/nvidia/nvlsm/third-party-notices.txt

NVLSM's third-party notices overlap with Fabric Manager's (libibumad, Google
Protobuffers, gRPC) — those are covered above. NVLSM additionally bundles:

1. Licensee's use of opensm is subject to the terms and conditions of the
OpenIB.org BSD (FreeBSD variant) License. All third-party software packages are
copyright by their respective authors. The OpenIB.org BSD (FreeBSD variant) License
terms and conditions are hereby incorporated into the Agreement by this reference.
https://github.com/linux-rdma/opensm/blob/master/COPYING
(License text is the same OpenIB.org BSD (FreeBSD Variant) reproduced above
under Fabric Manager's libibumad entry.)
```

---

## NVIDIA DCGM; version 4.5.1-1 (datacenter-gpu-manager-4-core + datacenter-gpu-manager-4-cuda13; 3.3.6-1 on AL2)

<https://developer.nvidia.com/dcgm>

```text

    * Package NVIDIA DCGM's source/binary may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/dependencies/nvidia_dcgm/
      Upstream source: https://github.com/NVIDIA/DCGM (Apache-2.0)

The installed DCGM packages (datacenter-gpu-manager-4-core,
datacenter-gpu-manager-4-cuda13) declare License: NVIDIA Proprietary in RPM
metadata and ship the "NVIDIA Data Center GPU Manager License" reproduced
below (v. January 22, 2021) at /usr/share/licenses/datacenter-gpu-manager-4-core-4.5.1/LICENSE
and the identical text at /usr/share/licenses/datacenter-gpu-manager-4-cuda13-4.5.1/LICENSE.
This proprietary license governs the binary packages as redistributed by
NVIDIA. A separate third-party-notices.txt (reproduced after this LICENSE)
covers open-source components bundled inside DCGM.

                 NVIDIA DATA CENTER GPU MANAGER LICENSE

This license is a legal agreement between you and NVIDIA Corporation ("NVIDIA")
and governs your use of the NVIDIA Data Center GPU Manager (DCGM) software and
materials provided hereunder ("SOFTWARE").

This license can be accepted only by an adult of legal age of majority in the
country in which the SOFTWARE is used. If you are under the legal age of
majority, you must ask your parent or legal guardian to consent to this license.
If you are entering into this license on behalf of a company or other legal
entity, you represent that you have legal authority and "you" will mean the
entity you represent.

By using the SOFTWARE, you affirm that you have reached the legal age of
majority, you accept the terms of this license, and you take legal and financial
responsibility for the actions of your permitted users.

You agree to use the SOFTWARE only for purposes that are permitted by (a) this
license, and (b) any applicable law, regulation or generally accepted practices
or guidelines in the relevant jurisdictions.

1. LICENSE
Subject to the terms of this license, NVIDIA hereby grants you a
non-exclusive, non-transferable license to install and use the SOFTWARE for your
purposes in systems with NVIDIA GPUs.

2. LIMITATIONS
Your license to use the SOFTWARE is restricted as follows:
a. You may not reverse engineer, decompile or disassemble, or remove copyright
or other proprietary notices from any portion of the SOFTWARE or copies of the
SOFTWARE.
b. You may not modify or create derivative works of any portion of the SOFTWARE.
c. Except as provided in this license, you may not sell, rent, sublicense,
transfer or distribute the SOFTWARE, or make its functionality available to
others.
d. You may not bypass, disable, or circumvent any technical limitations,
encryption, security, digital rights management or authentication mechanism in
the SOFTWARE.
e. You may not use the SOFTWARE in any manner that would cause it to become
subject to an open source software license. As examples, licenses that require
as a condition of use, modification, and/or distribution that the SOFTWARE be
(i) disclosed or distributed in source code form; (ii) licensed for the purpose
of making derivative works; or (iii) redistributable at no charge.

3. AUTHORIZED USERS
You may allow employees and contractors of your entity or
of your subsidiary(ies) to access and use the SOFTWARE from your secure network
to perform work on your behalf. If you are an academic institution you may allow
users enrolled or employed by the academic institution to access and use the
SOFTWARE from your secure network. You are responsible for the compliance with
the terms of this license by your authorized users.

4. UPDATES
NVIDIA is not obligated to support or update the SOFTWARE. This
license also applies to SOFTWARE patches, workarounds or other updates, unless
other terms accompany those items.

5. PRE-RELEASE VERSIONS
SOFTWARE versions identified as alpha, beta, preview,
early access or otherwise as pre-release may not be fully functional, may
contain errors or design flaws, and may have reduced or different security,
privacy, availability, and reliability standards relative to commercial versions
of NVIDIA software and materials. You may use a pre-release SOFTWARE version at
your own risk, understanding that these versions are not intended for use in
production or business-critical systems.

6. THIRD-PARTY COMPONENTS
The SOFTWARE may include third-party components with
separate legal notices or terms as may be described in proprietary notices
accompanying the SOFTWARE. If and to the extent there is a conflict between the
terms in this license and the third-party license terms, the third-party terms
control only to the extent necessary to resolve the conflict.

7. OWNERSHIP
NVIDIA reserves all rights, title and interest in and to the
SOFTWARE not expressly granted to you under this license. The SOFTWARE and the
related intellectual property rights therein are and will remain the sole and
exclusive property of NVIDIA or its licensors. The SOFTWARE is copyrighted and
protected by the laws of the United States and other countries, and
international treaty provisions.

8. FEEDBACK
You may, but are not obligated to, provide to NVIDIA suggestions,
fixes, modifications, feature requests or other feedback regarding the SOFTWARE
("Feedback"). For any Feedback that you voluntarily provide, you hereby grant
NVIDIA and its affiliates a perpetual, non-exclusive, worldwide, irrevocable
license to use, reproduce, modify, license, sublicense (through multiple tiers
of sublicensees), and distribute (through multiple tiers of distributors) the
Feedback without the payment of any royalties or fees to you. NVIDIA will use
Feedback at its choice.

9. NO WARRANTIES
THE SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY EXPRESS OR
IMPLIED WARRANTY OF ANY KIND INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF
MERCHANTABILITY, NONINFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. NVIDIA
DOES NOT WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS OR THAT THE
OPERATION THEREOF WILL BE UNINTERRUPTED OR ERROR-FREE, OR THAT ALL ERRORS WILL
BE CORRECTED. NVIDIA does not warrant or assume responsibility for the accuracy
or completeness of any information, text, graphics, links or other items
contained within the SOFTWARE.

10. LIMITATIONS OF LIABILITY
TO THE MAXIMUM EXTENT PERMITTED BY LAW, NVIDIA
AND ITS AFFILIATES SHALL NOT BE LIABLE FOR ANY SPECIAL, INCIDENTAL, PUNITIVE OR
CONSEQUENTIAL DAMAGES, OR ANY LOST PROFITS, PROJECT DELAYS, LOSS OF USE, LOSS OF
DATA OR LOSS OF GOODWILL, OR THE COSTS OF PROCURING SUBSTITUTE PRODUCTS, ARISING
OUT OF OR IN CONNECTION WITH THIS LICENSE OR THE USE OR PERFORMANCE OF THE
SOFTWARE, WHETHER SUCH LIABILITY ARISES FROM ANY CLAIM BASED UPON BREACH OF
CONTRACT, BREACH OF WARRANTY, TORT (INCLUDING NEGLIGENCE), PRODUCT LIABILITY OR
ANY OTHER CAUSE OF ACTION OR THEORY OF LIABILITY, EVEN IF NVIDIA HAS PREVIOUSLY
BEEN ADVISED OF, OR COULD REASONABLY HAVE FORESEEN, THE POSSIBILITY OF SUCH
DAMAGES. IN NO EVENT WILL NVIDIA"S AND ITS AFFILIATES TOTAL CUMULATIVE LIABILITY
UNDER OR ARISING OUT OF THIS LICENSE EXCEED US$10.00. THE NATURE OF THE
LIABILITY OR THE NUMBER OF CLAIMS OR SUITS SHALL NOT ENLARGE OR EXTEND THIS
LIMIT.

11. TERMINATION
Your rights under this license will terminate automatically
without notice from NVIDIA if you fail to comply with any term of this license
or if you commence or participate in any legal proceeding against NVIDIA with
respect to the SOFTWARE. NVIDIA may terminate this license with advance written
notice to you, if NVIDIA decides to no longer provide the SOFTWARE in a country
or, in NVIDIA"s sole discretion, the continued use of it is no longer
commercially viable. Upon any termination of this license, you agree to promptly
discontinue use of the SOFTWARE and destroy all copies in your possession or
control. All provisions of this license will survive termination, except for the
license granted to you.

12. APPLICABLE LAW
This license will be governed in all respects by the laws of
the United States and of the State of Delaware as those laws are applied to
contracts entered into and performed entirely within Delaware by Delaware
residents, without regard to the conflicts of laws principles. The United
Nations Convention on Contracts for the International Sale of Goods is
specifically disclaimed. You agree to all terms of this Agreement in the English
language. The state or federal courts residing in Santa Clara County, California
shall have exclusive jurisdiction over any dispute or claim arising out of this
license. Notwithstanding this, you agree that NVIDIA shall still be allowed to
apply for injunctive remedies or an equivalent type of urgent legal relief in
any jurisdiction.

13. NO ASSIGNMENT
This license and your rights and obligations thereunder may
not be assigned by you by any means or operation of law without NVIDIA"s
permission. Any attempted assignment not approved by NVIDIA in writing shall be
void and of no effect.

14. EXPORT
The SOFTWARE is subject to United States export laws and
regulations. You agree to comply with all applicable U.S. and international
export laws, including the Export Administration Regulations (EAR) administered
by the U.S. Department of Commerce and economic sanctions administered by the
U.S. Department of Treasury"s Office of Foreign Assets Control (OFAC). These
laws include restrictions on destinations, end-users and end-use. By accepting
this license, you confirm that you are not currently residing in a country or
region currently embargoed by the U.S. and that you are not otherwise prohibited
from receiving the SOFTWARE.

15. GOVERNMENT USE
The SOFTWARE is, and shall be treated as being, "Commercial
Items" as that term is defined at 48 CFR " 2.101, consisting of "commercial
computer software" and "commercial computer software documentation",
respectively, as such terms are used in, respectively, 48 CFR " 12.212 and 48
CFR "" 227.7202 & 252.227-7014(a)(1). Use, duplication or disclosure by the U.S.
Government or a U.S. Government subcontractor is subject to the restrictions in
this license pursuant to 48 CFR " 12.212 or 48 CFR " 227.7202. In no event shall
the US Government user acquire rights in the SOFTWARE beyond those specified in
48 C.F.R. 52.227-19(b)(1)-(2).

16. NOTICES
Please direct your legal notices or other correspondence to NVIDIA
Corporation, 2788 San Tomas Expressway, Santa Clara, California 95051, United
States of America, Attention: Legal Department.

17. ENTIRE AGREEMENT
This license is the final, complete and exclusive
agreement between the parties relating to the subject matter of this license and
supersedes all prior or contemporaneous understandings and agreements relating
to this subject matter, whether oral or written. If any court of competent
jurisdiction determines that any provision of this license is illegal, invalid
or unenforceable, the remaining provisions will remain in full force and effect.
This license may only be modified in a writing signed by an authorized
representative of each party.

(v. January 22, 2021)

Third-Party Components Bundled in NVIDIA DCGM
---------------------------------------------
Source: /usr/share/doc/datacenter-gpu-manager-4/third-party-notices.txt

This Third-Party Notices file provides notices and information about third
party components included in the SOFTWARE. The following third-party
components are licensed to Licensee pursuant to the following terms and conditions:


1. Licensee's use of Zlib 1.2.11 is subject to the terms and conditions of the ZLib license.
   All third-party software packages are copyright by their respective authors.
   The ZLib license terms and conditions are hereby incorporated into the Agreement by this reference.
   https://zlib.net/zlib_license.html

   Copyright (C) 1995-2017 Jean-loup Gailly and Mark Adler

   This software is provided 'as-is', without any express or implied
   warranty.  In no event will the authors be held liable for any damages
   arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it
   freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
      claim that you wrote the original software. If you use this software
      in a product, an acknowledgment in the product documentation would be
      appreciated but is not required.
   2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original software.
   3. This notice may not be removed or altered from any source distribution.

   Jean-loup Gailly        Mark Adler
   jloup@gzip.org          madler@alumni.caltech.edu


2. Licensee's use of OpenSSL 1.1.1d is subject to the terms and conditions of double OpenSSL and SSLeay licenses.
   All third-party software packages are copyright by their respective authors.
   The OpenSSL license and SSLeay license terms and conditions are hereby incorporated into the Agreement by this reference.
   https://www.openssl.org/source/license-openssl-ssleay.txt

   OpenSSL License

   Copyright (c) 1998-2019 The OpenSSL Project.  All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.

   3. All advertising materials mentioning features or use of this
      software must display the following acknowledgment:
      "This product includes software developed by the OpenSSL Project
      for use in the OpenSSL Toolkit. (http://www.openssl.org/)"

   4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
      endorse or promote products derived from this software without
      prior written permission. For written permission, please contact
      openssl-core@openssl.org.

   5. Products derived from this software may not be called "OpenSSL"
      nor may "OpenSSL" appear in their names without prior written
      permission of the OpenSSL Project.

   6. Redistributions of any form whatsoever must retain the following
      acknowledgment:
      "This product includes software developed by the OpenSSL Project
      for use in the OpenSSL Toolkit (http://www.openssl.org/)"

   THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
   EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
   ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
   OF THE POSSIBILITY OF SUCH DAMAGE.

   This product includes cryptographic software written by Eric Young
   (eay@cryptsoft.com).  This product includes software written by Tim
   Hudson (tjh@cryptsoft.com).


   Original SSLeay License

   Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
   All rights reserved.

   This package is an SSL implementation written
   by Eric Young (eay@cryptsoft.com).
   The implementation was written so as to conform with Netscapes SSL.

   This library is free for commercial and non-commercial use as long as
   the following conditions are aheared to.  The following conditions
   apply to all code found in this distribution, be it the RC4, RSA,
   lhash, DES, etc., code; not just the SSL code.  The SSL documentation
   included with this distribution is covered by the same copyright terms
   except that the holder is Tim Hudson (tjh@cryptsoft.com).

   Copyright remains Eric Young's, and as such any Copyright notices in
   the code are not to be removed.
   If this package is used in a product, Eric Young should be given attribution
   as the author of the parts of the library used.
   This can be in the form of a textual message at program startup or
   in documentation (online or textual) provided with the package.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:
   1. Redistributions of source code must retain the copyright
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
   3. All advertising materials mentioning features or use of this software
      must display the following acknowledgement:
      "This product includes cryptographic software written by
       Eric Young (eay@cryptsoft.com)"
      The word 'cryptographic' can be left out if the rouines from the library
      being used are not cryptographic related :-).
   4. If you include any Windows specific code (or a derivative thereof) from
      the apps directory (application code) you must include an acknowledgement:
      "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"

   THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
   OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
   OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
   SUCH DAMAGE.

   The licence and distribution terms for any publically available version or
   derivative of this code cannot be changed.  i.e. this code cannot simply be
   copied and put under another distribution licence
   [including the GNU Public Licence.]


3. Licensee's use of JsonCPP 1.8.4 is subject to the terms and conditions of the MIT License.
   All third-party software packages are copyright by their respective authors.
   The MIT License terms and conditions are hereby incorporated into the Agreement by this reference.
   https://github.com/open-source-parsers/jsoncpp/blob/1.8.4/LICENSE

   Copyright (c) 2007-2010 Baptiste Lepilleur and The JsonCpp Authors

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use, copy,
   modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.


4. Licensee's use of Libevent 2.1.8 is subject to the terms and conditions of the 3-clause BSD license.
   All third-party software packages are copyright by their respective authors.
   The 3-clause BSD license terms and conditions are hereby incorporated into the Agreement by this reference.
   https://github.com/libevent/libevent/blob/release-2.1.8-stable/LICENSE
(License text is identical to the libevent entry under the Fabric Manager
block above; copyright 2000-2007 Niels Provos / 2007-2012 Niels Provos and
Nick Mathewson.)


5. Licensee's use of Google Protocol Buffers 3.7.1 is subject to the terms and conditions of the 3-clause BSD license.
   https://github.com/protocolbuffers/protobuf/blob/v3.7.1/LICENSE
(License text is identical to the Google Protobuffers entry under the
Fabric Manager block above; Copyright 2008 Google Inc. 3-clause BSD.)


6. Licensee's use of TCLAP 1.2.2 is subject to the terms and conditions of the MIT license.
   All third-party software packages are copyright by their respective authors.
   The MIT license terms and conditions are hereby incorporated into the Agreement by this reference.
   https://sourceforge.net/p/tclap/code/ci/v1.2.2/tree/COPYING

   Copyright (c) 2003 Michael E. Smoot
   Copyright (c) 2004 Daniel Aarno
   Copyright (c) 2017 Google Inc.

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without restriction,
   including without limitation the rights to use, copy, modify, merge,
   publish, distribute, sublicense, and/or sell copies of the Software,
   and to permit persons to whom the Software is furnished to do so,
   subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
   AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
   IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.


7. Licensee's use of YAML-CPP 0.6.2 is subject of the terms and conditions of the MIT license.
   https://github.com/jbeder/yaml-cpp/blob/yaml-cpp-0.6.2/LICENSE

   Copyright (c) 2008-2015 Jesse Beder.

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.


8. Licensee's use of Catch2 2.9.2 is subject to the terms and conditions of the Boost Software License 1.0.
   https://github.com/catchorg/Catch2/blob/v2.9.2/LICENSE.txt

   Boost Software License - Version 1.0 - August 17th, 2003

   Permission is hereby granted, free of charge, to any person or organization
   obtaining a copy of the software and accompanying documentation covered by
   this license (the "Software") to use, reproduce, display, distribute,
   execute, and transmit the Software, and to prepare derivative works of the
   Software, and to permit third-parties to whom the Software is furnished to
   do so, all subject to the following:

   The copyright notices in the Software and this entire statement, including
   the above license grant, this restriction and the following disclaimer,
   must be included in all copies of the Software, in whole or in part, and
   all derivative works of the Software, unless such copies or derivative
   works are solely in the form of machine-executable object code generated by
   a source language processor.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
   SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
   FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.


9. Licensee's use of PLog 1.1.4 is subject to the terms and conditions of the Mozilla Public License 2.0.
   https://github.com/SergiusTheBest/plog/blob/1.1.4/LICENSE
   The full text of the MPL 2.0 license is available at https://www.mozilla.org/en-US/MPL/2.0
(Full MPL-2.0 text is reproduced in the Fabric Manager gRPC sub-section above; not duplicated here.)


10. Licensee's use of Fmtlib 8.0.0 is subject to the terms and conditions of the modified MIT license.
    https://github.com/fmtlib/fmt/blob/8.0.0/LICENSE.rst

    Copyright (c) 2012 - present, Victor Zverovich

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    --- Optional exception to the license ---

    As an exception, if, as a result of your compiling your source code, portions
    of this Software are embedded into a machine-executable object form of such
    source code, you may redistribute such embedded portions in such object form
    without including the above copyright and permission notices.


11. Licensee's use of cuda_memtest is subject to the terms and conditions of the Illinois Open Source License
    University of Illinois/NCSA
    Open Source License

    Copyright (c) 2009, University of Illinois.  All rights reserved.

    Developed by:

    Innovative Systems Lab
    National Center for Supercomputing Applications
    http://www.ncsa.uiuc.edu/AboutUs/Directorates/ISL.html

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal with
    the Software without restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
    Software, and to permit persons to whom the Software is furnished to do so, subject
    to the following conditions:

    * Redistributions of source code must retain the above copyright notice, this list
    of conditions and the following disclaimers.

    * Redistributions in binary form must reproduce the above copyright notice, this list
    of conditions and the following disclaimers in the documentation and/or other materials
    provided with the distribution.

    * Neither the names of the Innovative Systems Lab, the National Center for Supercomputing
    Applications, nor the names of its contributors may be used to endorse or promote products
    derived from this Software without specific prior written permission.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
    PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
    OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS WITH THE SOFTWARE.


12. Licensee's use of boost is subject to the terms and conditions of the Boost License
(Full Boost Software License 1.0 text is reproduced in items 8 and 12 of the
Fabric Manager block above and in DCGM item 8; not duplicated here.)
```

---

## EFA Installer; version 1.47.0

<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html>

```text

    * Package EFA Installer's source/binary may be found at:
      https://efa-installer.amazonaws.com/aws-efa-installer-1.47.0.tar.gz

The EFA Installer is an Amazon-packaged bundle containing:
  * AWS EFA kernel module and userspace (GPL-2.0 / BSD-2-Clause dual)
  * libfabric (BSD-2-Clause / GPL-2.0 dual)
  * Open MPI (BSD-3-Clause)
  * Amazon-contributed installer scripts (Apache-2.0)
Each sub-component's license text is distributed inside the EFA installer
tarball (see RELEASE_NOTES and LICENSE files within the archive).
```

---

## http-parser; version 2.9.4

<https://github.com/nodejs/http-parser>

```text

    * Package http-parser's source code may be found at:
      https://us-east-1-aws-parallelcluster.s3.us-east-1.amazonaws.com/archives/dependencies/http_parser/

Note: http-parser is only compiled from source on Amazon Linux 2023, where it
is not available in the OS repositories. It is a build-time dependency of
Slurm's REST API (slurmrestd).

MIT License

Copyright Joyent, Inc. and other Node contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

