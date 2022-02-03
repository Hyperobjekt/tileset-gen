# Creates GeoJSON files from Census shapefiles for 2020

census_ftp_base = ftp://ftp2.census.gov/geo/tiger/GENZ2020/shp/

block-groups-pattern = cb_2020_us_bg_500k.zip
tracts-pattern = cb_2020_us_tract_500k.zip
cities-pattern = cb_2020_us_place_500k.zip
counties-pattern = cb_2020_us_county_500k.zip
states-pattern = cb_2020_us_state_500k.zip

block-groups-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY + this.properties.TRACT + this.properties.BLKGRP"
tracts-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY + this.properties.TRACT"
cities-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.PLACE"
counties-geoid = "this.properties.GEOID = this.properties.STATE + this.properties.COUNTY"
states-geoid =  "this.properties.GEOID = this.properties.STATE"

geo_types = states counties cities tracts block-groups
GENERATED_FILES = $(foreach t, $(geo_types), 2020/$(t).geojson)
GZIP_FILES = $(foreach t, $(geo_types), 2020/$(t).geojson.gz)

.PHONY: all states counties cities tracts block-groups help

## all                 : Create all census GeoJSON
all: $(GENERATED_FILES)

all_gzip: $(GZIP_FILES)

states: 2020/states.geojson

counties: 2020/counties.geojson

cities: 2020/cities.geojson

tracts: 2020/tracts.geojson

block-groups: 2020/block-groups.geojson

## help                : Print help
help: Makefile
	perl -ne '/^## / && s/^## //g && print' $<

2020/%.geojson.gz: 2020/%.geojson
	gzip -c $< > $@

.SECONDARY:
deploy:
	for f in ./2020/*.geojson; do aws s3 cp $$f s3://hyperobjekt-geojson/2020/; done

.SECONDARY:
deploygz: 
	for f in ./2020/*.geojson.gz; do aws s3 cp $$f s3://hyperobjekt-geojson/2020/; done

## 2020/%.geojson    : Download and clean census GeoJSON
.SECONDARY:
2020/%.geojson:
	mkdir -p 2020/$*
	wget --no-use-server-timestamps -np -nd -r -P 2020/$* -A '$($*-pattern)' $(census_ftp_base)
	for f in ./2020/$*/*.zip; do unzip -d ./2020/$* $$f; done
	mapshaper ./2020/$*/*.shp combine-files \
		-each $($*-geoid) \
		-o $@ combine-layers format=geojson

