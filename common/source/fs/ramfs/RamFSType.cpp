/**
 * @file RamFSType.h
 */

#include "fs/ramfs/RamFSType.h"
#include "fs/ramfs/RamFSSuperblock.h"


RamFSType::RamFSType() : FileSystemType("ramfs")
{
}


RamFSType::~RamFSType()
{}


Superblock *RamFSType::readSuper ( Superblock *superblock, void* ) const
{
  return superblock;
}


Superblock *RamFSType::createSuper ( Dentry *root, uint32 s_dev ) const
{
  Superblock *super = new RamFSSuperblock ( root, s_dev );
  return super;
}
