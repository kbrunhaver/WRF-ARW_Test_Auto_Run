#!/usr/bin/bash

# Define Path if sim set up in home folder
# Otherwise just replace $HOME with folder containing WRF contents

MY_HOME=$HOME
DATA_DIR="$MY_HOME/DATA"
WPS_DIR="$MY_HOME/WPS"

cd "$MY_HOME" 

source activate ncl_stable

DIR=$PWD/wrf_dependencies
export NETCDF=$DIR/netcdf
export LD_LIBRARY_PATH=$NETCDF/lib:$DIR/grib2/lib
export PATH=$NETCDF/bin:$DIR/mpich/bin:${PATH}
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

# Navigate to WPS 
cd "$WPS_DIR" || { echo "Error: WPS directory not found!"; exit 1; }

export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

# Link the GFS Vtable
ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable
echo "Linked Vtable.GFS"

GRIB_DIR=$(find "$DATA_DIR" -type f -iname 'fnl*' -exec dirname {} \; | sort -u)

if [ -z "$GRIB_DIR" ]; then
    echo "Error: No GRIB data directories found in $DATA_DIR!"
    exit 1
fi

# Pass only the GRIB directory to link_grib.csh
RELATIVE_PATH=$(realpath --relative-to="$WPS_DIR" "$GRIB_DIR")
echo "Linking GRIB data from: $GRIB_DIR"
echo "$RELATIVE_PATH"
./link_grib.csh "$RELATIVE_PATH/fnl"

echo "GRIB DATA Linked"
echo "Please edit the namelist.wps file in the WPS directory."
echo "Please press any key"

read -r

cd "$WPS_DIR"

#checks if nano is installed
if command -v nano > /dev/null 2>&1; then
    nano namelist.wps
else
    # If no nano prompt for other editor
    echo "nano is not installed. Please edit the namelist.wps file manually in your preferred text editor."
    read -p "Press Enter to continue after editing the file."
fi

./ungrib.exe || true

geog_data_path="$MY_HOME/Build_WRF/WPS_GEOG"

if [ ! -d "$geog_data_path" ]; then
    echo "Error: Directory does not exist: $geog_data_path"
    echo "Please check your installation and ensure WPS_GEOG is correctly set up."
    exit 1
fi

ncl util/plotgrids_new.ncl &

NCL_PID=$! 

sleep 5  

echo "Press Enter to close the plot if you are satisfied or ctrl+c to exit the program to edit namelist file and rerun the program."
read -r  

pkill "$NCL_PID"

echo "Running geogrid.exe"

./geogrid.exe

echo "Running metgrid.exe"

./metgrid.exe

WRF_PATH="$MY_HOME/WRF"

cd $WRF_PATH/test/em_real

echo "Linking metgrid files to WRF."

ln -sf ../../../WPS/met_em.d01.* .

if command -v nano > /dev/null 2>&1; then
    nano namelist.input
else
    # If no nano prompt for other editor
    echo "nano is not installed. Please edit the namelist.input file manually in your preferred text editor."
    read -p "Press Enter to continue after editing the file."
fi

echo "Running real.exe"

./real.exe >& log.wrf

echo "Running wrf.exe"

./wrf.exe >& log.wrf






























