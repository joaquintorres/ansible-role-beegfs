*******
Vagrant driver installation guide
*******

All scenarios use Vagrant with libvirt (AlmaLinux boxes, extra disk at
``/dev/vdb``). CI runs them in ``.github/workflows/molecule.yml``.

Requirements
============

* KVM, libvirt and Vagrant with the ``vagrant-libvirt`` plugin

Install
=======

.. code-block:: bash

    $ vagrant plugin install vagrant-libvirt
    $ pip install -r molecule/requirements.txt
    $ ansible-galaxy collection install -r requirements.yml
    $ molecule test -s default
