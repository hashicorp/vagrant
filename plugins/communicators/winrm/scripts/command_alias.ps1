function which {
    $command = [Array](Get-Command $args[0] -errorAction SilentlyContinue)
    if($null -eq $command)
    {
      exit 1
    }
    write-host $command[0].Definition
    exit 0
}

function test ([Switch] $d, [String] $path) {
  if(Test-Path $path)
  {
    exit 0
  }
  exit 1
}

function chmod {
  exit 0
}

function chown {
  exit 0
}

function mkdir ([Switch] $p, [String] $path)
{
  if(Test-Path $path)
  {
    exit 0
  } else {
    New-Item $path -Type Directory -Force | Out-Null
  }
}
