insert into public.users (
  id, email, display_name, city, zip_code, language_preference
) values (
  '11111111-1111-1111-1111-111111111111',
  'demo@petgroomer.local',
  'Taylor Chen',
  'Fullerton',
  '92832',
  'en'
) on conflict (id) do nothing;

insert into public.pets (
  id, user_id, name, species, breed, breed_notes, weight, age, sex, coat_type, coat_condition, temperament, health_notes, grooming_history
) values
  (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Mochi',
    'dog',
    'Maltipoo',
    'Curly coat, compact body',
    15,
    4,
    'Male',
    'Curly',
    'Light matting',
    array['Anxious', 'Afraid of dryers'],
    'Sensitive around ears',
    'Regular grooming'
  ),
  (
    '22222222-2222-2222-2222-222222222223',
    '11111111-1111-1111-1111-111111111111',
    'Luna',
    'cat',
    'Domestic longhair',
    null,
    10,
    7,
    'Female',
    'Long hair',
    'Shedding',
    array['Calm', 'Senior pet'],
    null,
    'Previous bad experience'
  )
on conflict (id) do nothing;

insert into public.groomers (
  id, owner_user_id, name, bio, city, zip_code, service_radius, service_areas, languages, years_experience,
  service_methods, accepts_dogs, accepts_cats, size_accepted, specialties, price_min, price_max,
  phone, sms_number, instagram_url, wechat_id, website_url, email, is_verified, status, rating, review_count
) values
  (
    '33333333-3333-3333-3333-333333333331',
    '11111111-1111-1111-1111-111111111111',
    'Ava Park',
    'Independent stylist focused on doodles, poodles, and calm one-on-one sessions for nervous dogs.',
    'Fullerton',
    '92832',
    12,
    array['Fullerton', 'Brea', 'Anaheim'],
    array['English', 'Korean'],
    8,
    array['Home studio', 'Mobile grooming'],
    true,
    false,
    array['Small', 'Medium'],
    array['Doodle', 'Poodle', 'Teddy cut', 'Anxious pets'],
    85,
    165,
    '7145550124',
    '7145550124',
    'https://instagram.com/example',
    null,
    'https://example.com',
    'ava@example.com',
    true,
    'published',
    4.9,
    42
  ),
  (
    '33333333-3333-3333-3333-333333333332',
    null,
    'Mia Santos',
    'Gentle cat and senior pet grooming with clear price ranges and low-stress handling.',
    'Irvine',
    '92612',
    15,
    array['Irvine', 'Tustin', 'Costa Mesa'],
    array['English', 'Spanish'],
    6,
    array['In-home grooming'],
    true,
    true,
    array['Small', 'Medium', 'Cats'],
    array['Cats', 'Senior pets', 'De-matting', 'Sensitive skin'],
    95,
    180,
    '9495550199',
    '9495550199',
    null,
    null,
    null,
    'mia@example.com',
    true,
    'published',
    4.8,
    31
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    null,
    'Leo Wu',
    'Asian fusion styling and compact mobile appointments for small breeds across the San Gabriel Valley.',
    'Arcadia',
    '91007',
    18,
    array['Arcadia', 'Pasadena', 'Alhambra'],
    array['English', 'Mandarin'],
    10,
    array['Mobile grooming', 'Partner grooming station'],
    true,
    false,
    array['Small'],
    array['Asian fusion style', 'Bichon', 'Maltipoo', 'Small dogs'],
    105,
    210,
    null,
    '6265550188',
    'https://instagram.com/example',
    'leogrooms',
    null,
    'leo@example.com',
    false,
    'published',
    4.7,
    26
  )
on conflict (id) do nothing;

insert into public.groomer_portfolio (
  id, groomer_id, image_url, after_image_url, pet_species, breed, service_type, style_name, coat_condition, caption
) values
  (
    '44444444-4444-4444-4444-444444444441',
    '33333333-3333-3333-3333-333333333331',
    'mock://portfolio-doodle-teddy',
    'mock://portfolio-doodle-teddy-after',
    'dog',
    'Mini Goldendoodle',
    'Full groom',
    'Teddy cut',
    'Light matting',
    'Soft teddy face with practical body length for a curly coat.'
  ),
  (
    '44444444-4444-4444-4444-444444444442',
    '33333333-3333-3333-3333-333333333332',
    'mock://portfolio-cat-sanitary',
    'mock://portfolio-cat-sanitary-after',
    'cat',
    'Domestic longhair',
    'Cat grooming',
    'Sanitary trim',
    'Shedding',
    'Low-stress comb-out and sanitary trim for an older longhair cat.'
  ),
  (
    '44444444-4444-4444-4444-444444444443',
    '33333333-3333-3333-3333-333333333333',
    'mock://portfolio-bichon-round',
    'mock://portfolio-bichon-round-after',
    'dog',
    'Bichon',
    'Haircut',
    'Bichon round head',
    'Normal',
    'Round head and balanced legs for a clean Asian fusion profile.'
  )
on conflict (id) do nothing;

insert into public.pet_photos (pet_id, user_id, image_url, photo_type, is_primary) values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'mock://mochi-front', 'front', true),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'mock://mochi-coat', 'coat_close_up', false),
  ('22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', 'mock://luna-side', 'side', true);

insert into public.reviews (
  user_id, groomer_id, pet_id, overall_rating, grooming_result_rating, communication_rating,
  patience_rating, punctuality_rating, price_transparency_rating, would_rebook, service_type, review_text, service_date
) values
  (
    '11111111-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333331',
    '22222222-2222-2222-2222-222222222222',
    5, 5, 5, 5, 5, 5, true, 'Full groom',
    'Ava explained every step and Mochi came home calm with the exact teddy face I asked for.',
    current_date
  ),
  (
    '11111111-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333332',
    '22222222-2222-2222-2222-222222222223',
    4.8, 5, 5, 5, 4, 5, true, 'Cat grooming',
    'Clear pricing, quiet setup, and a patient approach for Luna.',
    current_date
  );

insert into public.favorites (user_id, target_type, target_id) values
  ('11111111-1111-1111-1111-111111111111', 'groomer', '33333333-3333-3333-3333-333333333331'),
  ('11111111-1111-1111-1111-111111111111', 'portfolio', '44444444-4444-4444-4444-444444444441')
on conflict (user_id, target_type, target_id) do nothing;

insert into public.quote_requests (
  id, user_id, groomer_id, pet_id, service_type, preferred_time, notes, contact_preference, status
) values
  (
    '55555555-5555-5555-5555-555555555551',
    '11111111-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333331',
    '22222222-2222-2222-2222-222222222222',
    'Full groom',
    'This weekend',
    'Mochi has light matting around the ears and gets nervous around dryers.',
    'SMS',
    'submitted'
  ),
  (
    '55555555-5555-5555-5555-555555555552',
    '11111111-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333331',
    null,
    'Face trim',
    'Next week',
    'Looking for a quick cleanup before family photos.',
    'Email',
    'viewed'
  )
on conflict (id) do nothing;
