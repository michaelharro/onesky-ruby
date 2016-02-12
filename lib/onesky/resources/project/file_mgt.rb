require 'base64'
require 'time'

module Resources
  module Project
    module FileMgt

      def list_file
        get("#{project_path}/files")
      end

      def upload_file(params)
        file = params[:file]
        if file.is_a?(String)
          raise IOError, 'File does not exist' unless File.exists?(file)
          params[:file] = File.new(file, 'rt')
        end

        post_multipart("#{project_path}/files", params)
      end

      def upload_screenshots(params)
        screenshots = screenshots_from_params(params)
        body = {:screenshots => screenshots}

        post("#{project_path}/screenshots", body)
      end

      def delete_file(params)
        delete("#{project_path}/files", params)
      end

      private

      def screenshots_from_params(params)

        return params[:screenshots] if params[:screenshots]

        file = params[:file]
        folder = params[:folder]
        tags = params[:tags]
        since = params[:since]
        screenshots = []

        if file.is_a?(String) && File.exists?(file) && tags.is_a?(Array) && tags.count > 0
          tags_for_file = tags.select{ |tag| !tag.has_key?(:file) || tag[:file] == file }
          screenshots = [screenshot_from_file_tags(file, tags_for_file)]
        end

        if folder.is_a?(String) && File.directory?(folder) && tags.is_a?(Array) && tags.count > 0
          screenshots = screenshots_from_folder_tags(folder, tags, since)
        end

        screenshots
      end

      def screenshots_from_folder_tags(folder, tags, since)
        screenshots = []
        Dir.foreach(folder) { |file|
          if (File.extname(file) == '.png' || File.extname(file) == '.jpg') && ()!since || File.mtime(file).utc > since.utc)
            tags_for_file = tags.select{ |tag| !tag.has_key?(:file) || tag[:file] == file }
            screenshots.push(screenshot_from_file_tags(File.join(folder, file), tags_for_file))
          end
        }

        screenshots
      end

      def screenshot_from_file_tags(file, tags)
        screenshot = []
        screenshot[:name] = File.basename(file)
        screenshot[:image] = Base64.encode64(File.open(file, 'rb').read)
        screenshot[:tags] = tags

        screenshot
      end

    end
  end
end
