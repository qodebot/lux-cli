#!/usr/bin/env python3
# coding: utf-8
# by QODEPARTY


import sys

from os import path, remove, rename, umask

#removedirs rmdir replace stat walk listdir

from datetime import datetime
from subprocess import check_output
from pathlib import Path #Path().rename()
from shutil import move, copy2


#===========================================================
if __name__ == '__main__':
  module_path = path.abspath(path.join('..'))
  if module_path not in sys.path:
    sys.path.append(module_path)

  lib_path = path.abspath(path.join(path.dirname(__file__), '..'))
  if lib_path not in sys.path:
    sys.path.append(lib_path)
#===========================================================


from term import debug, err, warn, info, ok, silly, rainbow, const as term, NL

#from sedtools import sed_find_block
from libassert import assert_shell_perms

#===========================================================







#===========================================================
def touch_file(src):
  pass

def move_file(src,dest):
  try:
    assert_shell_perms('mv')

  except FileNotFoundError as e:
    pass

def copy_file(src,dest):
  try:
    assert_shell_perms('mv')

  except FileNotFoundError as e:
    pass

def rename_file(src,dest):
  try:
    assert_shell_perms('rename')
    rename(src,dest)
  except FileNotFoundError as e:
    pass

def rem_file(src):
  try:
    assert_shell_perms('rm')
    if is_file(src): remove(src)
  except FileNotFoundError as e:
    err(f'File [{src}] does not exist.')

def path_type(src):
  ref=Path(src)
  if ref.exists():
    if ref.is_file(): return 'file'
    elif ref.is_dir(): return 'dir'
  return None

def mkdir_rec(src):
  try:
    ref=Path(src)
    ref.parent.absolute()
    ref.parent.mkdir(parents=True, exist_ok=True)


def is_file(src):
  try:
    ref=Path(src)
    ret=ref.is_file()
  except FileNotFoundError as e:
    ret=False
  return ret


def is_dir(src):
  try:
    ref=Path(src)
    ret=ref.is_dir()
  except FileNotFoundError as e:
    ret=False
  return ret

def get_homedir():
  return Path('~').expanduser()

def assert_file_exists(file):
  if not is_file(file):
    msg=f'{rainbow.RED}Required file {file} not found. Command not run.{term.RESET}'
    raise FileNotFoundError(msg)

#===========================================================






#===========================================================
def grep_cmd(cmd, src, **options):
  assert_shell_perms('grep')

def grep_filetype(): pass

#===========================================================



#===========================================================

def find_cmd(cmd, src, **options):
  assert_shell_perms('find')

def find_filetype(): pass
#   list=($($cmd_find "$LUX_HOME/www/${path}" -type f -name "*.${ftype}" ! -name '_*.*' -printf '%P\n' ))


  # function find_dirs(){
  #   info "Finding repo folders..."
  #   warn "This may take a few seconds..."
  #   this="$cmd_find ${2:-.} -mindepth 1"
  #   [[ $1 =~ "1" ]] && this+=" -maxdepth 2" || :
  #   [[ $1 =~ git ]] && this+=" -name .git"  || :
  #   this+=" -type d ! -path ."
  #   awk_cmd="awk -F'.git' '{ sub (\"^./\", \"\", \$1); print \$1 }'"
  #   cmd="$this | $awk_cmd"
  #   __print "$cmd"
  #   eval "$cmd" #TODO:check if theres a better way to do this
  # }

#===========================================================



#===========================================================
#sort of like a unit test lol
def unit_test():
  try:
    assert_shell_perms('mv')
    file1='../../inf/.testrc'
    file2='../../inf/.include'
    dir1='../../inf/'
    print(path_type(dir1))
    print(path_type(file1))
    print(path_type('./moo'))


    return 0
  except KeyboardInterrupt:
    info('\nDone')

#===========================================================

if __name__ == '__main__':
  import sys
  status = unit_test()
  sys.exit(status)

#--------------------------------
