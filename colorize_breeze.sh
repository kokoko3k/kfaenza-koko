#!/bin/bash

#!/bin/bash

echo source tint percent


source=$1
tint=$2
dest=$1.tint.png

 convert $source -fill "$tint" -tint 100% $dest

