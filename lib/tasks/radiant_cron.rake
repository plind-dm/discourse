# frozen_string_literal: true

namespace :radiant do
    desc "Radiant Task: remove user from group"   # description.
    task :radiant_task => :environment do
      proposer_group = Group.find_by(name: "rfp-author")
      read_only_group = Group.find_by(name: "rfp-commenter")
      proposers = proposer_group.users
      readers = read_only_group.users
    
       proposers.each do |user|
       if user.lock_timestamp == nil
            user.groups.delete(proposer_group)
            user.save
       elsif Time.now - 1800 > user.lock_timestamp
             user.groups.delete(proposer_group)
             user.save!
         end
       end
    
       readers.each do |user|
       if user.lock_timestamp == nil
            user.groups.delete(read_only_group)
            user.save
       elsif Time.now - user.lock_timestamp > 1800
            user.groups.delete(read_only_group)
            user.save!
        end
       end
    end
end
    