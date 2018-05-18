# Unit tests for circuit-oneops-1/components/cookbooks/compute/libraries/compute_until.rb


require_relative '../../../libraries/compute_util'
require_relative 'image'

describe 'get_image' do
  # Set up data set
  images = Array.new
  File.foreach('./spec/list_of_images.txt') do |line|
    image = line.split(',')
    images << Image.new(image[1].gsub("\n", ''),image[0])
  end

  # Base unchanging vars
  default_image = Image.new('CentOS-7.3.1611-x86_64-minimal-cloud-init RC10', 'rdhj3563-563d-563d-563d-rdhj3563xfgh')
  ostype = 'someos-1.0'
  latest = /20190309-1567/i
  # ----- TESTING_MODE
  context 'When TESTING_MODE flag is on' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), 'True', 'true', default_image, false, ostype)
      expect(return_image.name).to match(/[a-zA-Z]{1,20}-#{ostype.gsub(/\./, "")}-\d{4}-v\d{8}-\d{4}/i)
      expect(return_image.name).to match(latest)
      expect(return_image.name).to match(/snapshot/i)
    end
  end

  context 'When both flags are booleans' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), true, true, default_image, false, ostype)
      expect(return_image.name).to match(/[a-zA-Z]{1,20}-#{ostype.gsub(/\./, "")}-\d{4}-v\d{8}-\d{4}/i)
      expect(return_image.name).to match(latest)
      expect(return_image.name).to match(/snapshot/i)
    end
  end

  context 'When TESTING_MODE flag is off' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), 'true', 'False', default_image, false, ostype)
      expect(return_image.name).to match(/[a-zA-Z]{1,20}-#{ostype.gsub(/\./, "")}-\d{4}-v\d{8}-\d{4}/i)
      expect(return_image.name).to match(latest)
    end
  end

  context 'When TESTING_MODE flag is nil' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), 'True', nil, default_image, false, ostype)
      expect(return_image.name).to match(/[a-zA-Z]{1,20}-#{ostype.gsub(/\./, "")}-\d{4}-v\d{8}-\d{4}/i)
      expect(return_image.name).to match(latest)
    end
  end
  
  # ----- FAST_IMAGE
  context 'When FAST_IMAGE flag is false' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), nil, true, default_image, false, ostype)
      expect(return_image.name).to eql(default_image.name)
    end
  end

  context 'When FAST_IMAGE flag is nil' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), nil, 'true', default_image, false, ostype)
      expect(return_image.name).to eql(default_image.name)
    end
  end


  # ----- bearmetal
  context 'When flavor includes baremetal' do
    it '' do
      return_image = get_image(images, Image.new('faefeafbaremetalfafefa', 'randomString'), 'true', 'true', default_image, false, ostype)
      expect(return_image.name).to eql(default_image.name)
    end
  end

  # ----- User input
  context 'When user inputs image ID' do
    it '' do
      return_image = get_image(images, Image.new('randomString', 'randomString'), 'true', 'true', default_image, true, ostype)
      expect(return_image.name).to eql(default_image.name)
    end
  end
end