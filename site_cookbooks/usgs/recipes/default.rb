#
# Cookbook Name:: usgs
# Recipe:: default
#
# Copyright 2015, John Aguinaldo
#
# All rights reserved - Do Not Redistribute
#

case node[:platform]
	when "centos"

		['vim', 'mlocate', 'unzip'].each do |pkg|
			package pkg
		end
	else
		Chef::Log.info("Unsupported platform #{node[:platform]}")
end