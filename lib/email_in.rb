# frozen_string_literal: true

# source: lib/email/receiver.rb

module ::Email
  class Receiver
    def self.email_extension_reply_by_email_address_regex
      reply_addresses =
        SiteSetting
          .email_extension_reply_by_email_address
          .split("|")
          .map do |ad|
            ad = Regexp.escape(ad)
            ad.gsub!("\+", "\+?")
            ad.gsub!(Regexp.escape("%{post_id}"), "([0-9]+)")
          end
      if reply_addresses.empty?
        /$a/ # a regex that can never match
      else
        /#{reply_addresses.join("|")}/
      end
    end

    def self.email_extension_get_reply_to_post_by_subject(subject_str)
      SiteSetting
        .email_extension_topic_reply_subject_headers
        .split("|")
        .map do |header|
          match =
            subject_str.start_with?(header) && /#{Regexp.escape header}([\s\S]+)/.match(subject_str)
          if match && match.captures
            match.captures.each do |c|
              next if c.blank?
              topics = Topic.where(title: c.strip)
              next if topics.empty?
              # We should replace it to another Error instead in feature
              raise ReplyNotAllowedError if topics.size > 1
              post = Post.find_by(topic_id: topics[0].id, post_number: 1)
              return post if post
            end
          end
        end

      # return nil if not found
      nil
    end

    def self.check_address(address, include_verp = false)
      # only check for a group/category when 'email_in' is enabled
      if SiteSetting.email_in
        group = Group.find_by_email(address)
        return group if group

        category = Category.find_by_email(address)
        return category if category
      end

      # reply
      match = Email::Receiver.reply_by_email_address_regex(true, include_verp).match(address)
      if match && match.captures
        match.captures.each do |c|
          next if c.blank?
          post_reply_key = PostReplyKey.find_by(reply_key: c)
          return post_reply_key if post_reply_key
        end
      end

      # reply extension
      return nil unless SiteSetting.email_extension_enabled
      match = Email::Receiver.email_extension_reply_by_email_address_regex().match(address)
      if match && match.captures
        match.captures.each do |c|
          next if c.blank?
          post_reply_to = Post.find_by(id: c)
          return post_reply_to if post_reply_to
        end
      end

      nil
    end

    def process_destination(destination, user, body, elided)
      if SiteSetting.forwarded_emails_behaviour != "hide" && has_been_forwarded? &&
           process_forwarded_email(destination, user)
        return
      end

      return if is_bounce? && !destination.is_a?(PostReplyKey)

      if destination.is_a?(Group)
        user ||= stage_from_user
        create_group_post(destination, user, body, elided)
      elsif destination.is_a?(Category)
        if (user.nil? || user.staged?) && !destination.email_in_allow_strangers
          raise StrangersNotAllowedError
        end

        user ||= stage_from_user

        if !user.has_trust_level?(SiteSetting.email_in_min_trust) && !sent_to_mailinglist_mirror?
          raise InsufficientTrustLevelError
        end

        post = Email::Receiver.email_extension_get_reply_to_post_by_subject(subject)

        if post
          create_reply(
            user: user,
            raw: body,
            elided: elided,
            post: post,
            topic: post&.topic,
            skip_validations: user.staged?,
            bounce: is_bounce?,
          )
        else
          create_topic(
            user: user,
            raw: body,
            elided: elided,
            title: subject,
            category: destination.id,
            skip_validations: user.staged?,
          )
        end
      elsif destination.is_a?(PostReplyKey)
        # We don't stage new users for emails to reply addresses, exit if user is nil
        raise BadDestinationAddress if user.blank?

        post = Post.with_deleted.find(destination.post_id)
        raise ReplyNotAllowedError if !Guardian.new(user).can_create_post?(post&.topic)

        if destination.user_id != user.id && !forwarded_reply_key?(destination, user)
          raise ReplyUserNotMatchingError,
                "post_reply_key.user_id => #{destination.user_id.inspect}, user.id => #{user.id.inspect}"
        end

        create_reply(
          user: user,
          raw: body,
          elided: elided,
          post: post,
          topic: post&.topic,
          skip_validations: user.staged?,
          bounce: is_bounce?,
        )
      elsif destination.is_a?(Post)
        # reply extension
        if (user.nil? || user.staged?) && destination.topic.category.is_a?(Category) &&
             !destination.topic.category.email_in_allow_strangers
          raise StrangersNotAllowedError
        end

        user ||= stage_from_user

        if !user.has_trust_level?(SiteSetting.email_in_min_trust) && !sent_to_mailinglist_mirror?
          raise InsufficientTrustLevelError
        end

        raise BadDestinationAddress if user.blank?
        raise ReplyNotAllowedError if !Guardian.new(user).can_create_post?(destination&.topic)

        create_reply(
          user: user,
          raw: body,
          elided: elided,
          post: destination,
          topic: destination&.topic,
          skip_validations: user.staged?,
          bounce: is_bounce?,
        )
      end
    end
  end
end
